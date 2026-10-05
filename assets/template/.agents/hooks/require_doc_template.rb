#!/usr/bin/env ruby
# frozen_string_literal: true

# PreToolUse hook (Write): PRDs and convention files must start from their _TEMPLATE.md. Exit 2 blocks
# the write and shows stderr to the agent.

require 'json'

def headings(text)
  text.lines.select { |line| line.start_with?('## ') }.map(&:strip)
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
match = rel.match(%r{\Adocs/(product|conventions)/([^/]+\.md)\z})
exit 0 if match.nil? || match[2] == '_TEMPLATE.md'

kind = match[1]
template = File.join(project_dir, 'docs', kind, '_TEMPLATE.md')
exit 0 unless File.file?(template)

content = input.dig('tool_input', 'content').to_s
problems = []
problems << 'start with a `# Title` line' unless content.lstrip.start_with?('# ')
problems << "delete the template's <!-- guidance --> comments" if content.include?('<!--')
# Convention sections are optional by design; PRD sections are not.
if kind == 'product'
  missing = headings(File.read(template)) - headings(content)
  if missing.any?
    problems << "keep every template section, leaving {placeholders} for unknowns; missing: #{missing.join(', ')}"
  end
end
exit 0 if problems.empty?

warn "#{rel} must follow docs/#{kind}/_TEMPLATE.md:\n#{problems.map { |p| "- #{p}" }.join("\n")}"
exit 2
