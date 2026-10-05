#!/usr/bin/env ruby
# frozen_string_literal: true

# PreToolUse hook (Edit|Write): point the agent at each docs/conventions/*.md whose `<!-- paths: -->`
# globs in docs/CONVENTIONS.md match the edited file. Non-blocking, and once per convention per session.

require 'json'
require 'tmpdir'
require 'fileutils'

# `- [Title](conventions/<slug>.md) — <description> <!-- paths: g1, g2 -->`
INDEX_LINE = %r{\A-\s*\[.*?\]\(conventions/([\w-]+)\.md\)\s*—\s*(.*)\z}
PATHS_COMMENT = /<!--\s*paths:\s*(.*?)\s*-->/
# Splits on commas or whitespace, but keeps `{rb,erb}` whole.
GLOB = /(?:\{[^}]*\}|[^,\s])+/
# FNM_DOTMATCH so `**/*.rb` reaches `.agents/` and `.github/`.
GLOB_FLAGS = File::FNM_PATHNAME | File::FNM_EXTGLOB | File::FNM_DOTMATCH

def conventions(project_dir)
  index = File.join(project_dir, 'docs', 'CONVENTIONS.md')
  return [] unless File.exist?(index)

  in_fence = false
  File.readlines(index).filter_map do |line|
    # Skips the shape example in the index's code fence.
    if line.lstrip.start_with?('```')
      in_fence = !in_fence
      next
    end
    m = !in_fence && line.strip.match(INDEX_LINE)
    next unless m

    slug = m[1]
    next unless File.exist?(File.join(project_dir, 'docs', 'conventions', "#{slug}.md"))

    rest = m[2]
    globs = rest[PATHS_COMMENT, 1].to_s.scan(GLOB)
    description = rest.sub(PATHS_COMMENT, '').strip.sub(/\.\z/, '')
    { slug: slug, description: description, globs: globs }
  end
end

# With FNM_PATHNAME a bare `**` only matches top-level names, but Copilot's `applyTo: "**"`
# means every file.
def glob_match?(glob, path)
  glob == '**' || File.fnmatch?(glob, path, GLOB_FLAGS)
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

fresh = matched.reject do |conv|
  marker = File.join(marker_dir, conv[:slug])
  seen = File.exist?(marker)
  FileUtils.touch(marker)
  seen
end
exit 0 if fresh.empty?

lines = fresh.map { |conv| "  • docs/conventions/#{conv[:slug]}.md — #{conv[:description]}" }
puts JSON.generate(
  hookSpecificOutput: {
    hookEventName: 'PreToolUse',
    additionalContext: "📐 Convention docs that apply to `#{rel}`. Read the relevant one(s) before editing:\n" \
                       "#{lines.join("\n")}"
  }
)
