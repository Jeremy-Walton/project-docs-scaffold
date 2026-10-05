#!/usr/bin/env ruby
# frozen_string_literal: true

# PreToolUse hook (Edit|Write): point the agent at each docs/conventions/*.md whose `<!-- paths: -->`
# globs in docs/CONVENTIONS.md match the edited file. Non-blocking, and once per convention per session.

require 'json'
require 'tmpdir'
require 'fileutils'

# Index entries look like `- [Title](conventions/<slug>.md) — <description> <!-- paths: g1, g2 -->`,
# but only the link and the paths comment are required.
LINK = %r{\]\(conventions/([\w-]+)\.md\)}
PATHS_COMMENT = /<!--\s*paths:\s*(.*?)\s*-->/
# Splits on commas or whitespace, but keeps `{rb,erb}` whole.
GLOB = /(?:\{[^}]*\}|[^,\s])+/
# FNM_DOTMATCH so `**/*.rb` reaches `.agents/` and `.github/`.
GLOB_FLAGS = File::FNM_PATHNAME | File::FNM_EXTGLOB | File::FNM_DOTMATCH

# Entries whose doc doesn't exist are dropped, which also skips the index's `slug.md` shape example.
def conventions(project_dir)
  index = File.join(project_dir, 'docs', 'CONVENTIONS.md')
  return [] unless File.exist?(index)

  File.readlines(index).filter_map do |line|
    link = line.match(LINK)
    globs = line[PATHS_COMMENT, 1]
    next unless link && globs
    next unless File.exist?(File.join(project_dir, 'docs', 'conventions', "#{link[1]}.md"))

    description = link.post_match.sub(PATHS_COMMENT, '').sub(/\A\s*[—–-]+/, '').strip.delete_suffix('.')
    { slug: link[1], description: description, globs: globs.scan(GLOB) }
  end
end

# With FNM_PATHNAME a trailing `**` only matches one level, but `app/**` (or Copilot's `applyTo: "**"`)
# means everything below.
def glob_match?(glob, path)
  File.fnmatch?(glob.sub(/\*\*\z/, '**/*'), path, GLOB_FLAGS)
end

input = begin
  JSON.parse($stdin.read)
rescue StandardError
  {}
end
file_path = input.dig('tool_input', 'file_path').to_s
exit 0 if file_path.empty?

project_dir = File.expand_path(ENV.fetch('CLAUDE_PROJECT_DIR', Dir.pwd))
abs_path = File.expand_path(file_path, project_dir)
exit 0 unless abs_path.start_with?("#{project_dir}/")

rel = abs_path.delete_prefix("#{project_dir}/")

matched = conventions(project_dir).select do |conv|
  conv[:globs].any? { |glob| glob_match?(glob, rel) }
end
exit 0 if matched.empty?

session_id = input['session_id'].to_s
session_id = 'default' if session_id.empty?
marker_dir = File.join(Dir.tmpdir, "claude-conventions-#{session_id}")
FileUtils.mkdir_p(marker_dir)

fresh = matched.reject { |conv| File.exist?(File.join(marker_dir, conv[:slug])) }
exit 0 if fresh.empty?

FileUtils.touch(fresh.map { |conv| File.join(marker_dir, conv[:slug]) })
lines = fresh.map do |conv|
  ["  • docs/conventions/#{conv[:slug]}.md", conv[:description]].reject(&:empty?).join(' — ')
end
puts JSON.generate(
  hookSpecificOutput: {
    hookEventName: 'PreToolUse',
    additionalContext: "📐 Convention docs that apply to `#{rel}`. Read the relevant one(s) before editing:\n" \
                       "#{lines.join("\n")}"
  }
)
