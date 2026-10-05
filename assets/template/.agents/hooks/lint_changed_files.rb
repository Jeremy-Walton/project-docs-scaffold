#!/usr/bin/env ruby
# frozen_string_literal: true

# Stop hook: autocorrect and lint the uncommitted files this session edited, and block the stop
# (exit 2, output on stderr) on whatever the fixers couldn't resolve. A clean file set is cached by
# mtime so turns that change nothing don't pay for the linters again.

require 'json'
require 'open3'
require 'digest'
require 'tmpdir'

MAX_LINES = 30

# Only project-local tools, so a project gets the versions it pins and npx never downloads one.
TOOL_DIRS = %w[bin node_modules/.bin .venv/bin].freeze
JS = /\.(jsx?|tsx?|mjs|cjs)\z/
CSS = /\.s?css\z/
PY = /\.pyi?\z/

def ruby?(file)
  file.match?(%r{\.(rb|rake|ru|gemspec)\z|(\A|/)Gemfile\z}) ||
    (file.start_with?('bin/') && File.open(file, &:gets).to_s.match?(/\A#!.*ruby/))
end

# Each group runs the first of its tools the project has installed, and is skipped if it has none.
# Fixers run first so only what they can't resolve reaches the agent. Formatters run last because the
# fixers can leave formatting they would change.
LINTERS = [
  { tools: [%w[standardrb --fix --force-exclusion], %w[rubocop -a --force-exclusion --format simple]],
    files: method(:ruby?) },
  { tools: [%w[erb_lint --autocorrect], %w[erblint --autocorrect]], files: /\.erb\z/ },
  { tools: [%w[slim-lint]], files: /\.slim\z/ },
  { tools: [%w[haml-lint --auto-correct]], files: /\.haml\z/ },
  { tools: [%w[ruff check --fix]], files: PY },
  { tools: [%w[oxlint --fix]], files: JS },
  { tools: [%w[eslint --fix]], files: JS },
  { tools: [%w[stylelint --fix]], files: CSS },
  { tools: [%w[ruff format]], files: PY },
  { tools: [%w[biome check --write --no-errors-on-unmatched --files-ignore-unknown=true],
            %w[oxfmt --write --no-error-on-unmatched-pattern],
            %w[prettier --write --log-level warn --ignore-unknown]],
    files: Regexp.union(JS, CSS, /\.(json|md)\z/) }
].freeze

def installed(tools)
  tools.each do |name, *args|
    path = TOOL_DIRS.map { |dir| File.join(dir, name) }.find { |p| File.executable?(p) }
    return [path, *args] if path
  end
  nil
end

input = begin
  JSON.parse($stdin.read)
rescue StandardError
  {}
end
# Set when the agent is already continuing because of a Stop hook; blocking again would loop forever.
exit 0 if input['stop_hook_active']

transcript = input['transcript_path'].to_s
exit 0 unless File.exist?(transcript)

project_dir = File.expand_path(ENV.fetch('CLAUDE_PROJECT_DIR', Dir.pwd))
Dir.chdir(project_dir)

# Only sees Edit/Write tool calls, not files changed through Bash.
edited = []
File.foreach(transcript) do |line|
  next unless line.include?('"tool_use"') && line.match?(/"name":\s*"(Edit|Write)"/)

  content = JSON.parse(line).dig('message', 'content')
  next unless content.is_a?(Array)

  content.each do |part|
    next unless part['type'] == 'tool_use' && %w[Edit Write].include?(part['name'])

    path = File.expand_path(part.dig('input', 'file_path').to_s, project_dir)
    edited << path.delete_prefix("#{project_dir}/") if path.start_with?("#{project_dir}/")
  end
rescue JSON::ParserError
  next
end
exit 0 if edited.empty?

edited.uniq!
# --relative and ls-files both print paths relative to the project dir, which may be a monorepo subfolder.
changed = Open3.capture2('git', 'diff', '--name-only', '--relative', 'HEAD', '--', *edited, err: File::NULL)
               .first.lines(chomp: true) +
          Open3.capture2('git', 'ls-files', '-o', '--exclude-standard', '--', *edited, err: File::NULL)
               .first.lines(chomp: true)
files = (changed & edited).select { |f| File.file?(f) }
exit 0 if files.empty?

runs = LINTERS.filter_map do |group|
  paths = files.select { |f| group[:files] === f }
  command = installed(group[:tools]) unless paths.empty?
  [command, paths] if command
end
exit 0 if runs.empty?

# Keyed on the commands too, so installing a linter re-checks files that were clean without it.
cache = File.join(Dir.tmpdir, "claude-lint-clean-#{Digest::SHA1.hexdigest(project_dir)[0, 12]}")
fingerprint = lambda do
  Digest::SHA1.hexdigest((runs.map(&:first) + files.sort.map { |f| "#{f}:#{File.mtime(f).to_f}" }).join("\n"))
end
exit 0 if File.exist?(cache) && File.read(cache) == fingerprint.call

failures = runs.filter_map do |command, paths|
  output, status = Open3.capture2e(*command, *paths)
  next if status.success?

  lines = output.lines.reject { |l| l.include?('[Corrected]') }.map(&:rstrip).reject(&:empty?)
  lines = lines.first(MAX_LINES) + ["... #{lines.size - MAX_LINES} more lines"] if lines.size > MAX_LINES
  "$ #{command.join(' ')}\n#{lines.join("\n")}"
end

if failures.empty?
  File.write(cache, fingerprint.call)
  exit 0
end

warn "Lint offenses the autocorrectors couldn't fix in files you edited. Fix them before finishing.\n\n" \
     "#{failures.join("\n\n")}"
exit 2
