#!/usr/bin/env ruby
# frozen_string_literal: true

# Stop hook: every doc must be linked from the index that owns it. Exit 2 keeps the agent working and
# shows stderr to it.

require 'json'
require 'pathname'

# [docs to check, index file that must link each one]
INDEXES = [
  ['docs/*.md', 'AGENTS.md'],
  ['docs/*.md', 'README.md'],
  ['docs/product/*.md', 'docs/PRODUCT.md'],
  ['docs/conventions/*.md', 'docs/CONVENTIONS.md']
].freeze

input = begin
  JSON.parse($stdin.read)
rescue StandardError
  {}
end
# Set when the agent is already continuing because of a Stop hook; nagging again would loop forever.
exit 0 if input['stop_hook_active']

Dir.chdir(ENV.fetch('CLAUDE_PROJECT_DIR', Dir.pwd))

missing = INDEXES.flat_map do |pattern, index|
  next [] unless File.file?(index)

  text = File.read(index)
  Dir.glob(pattern).sort.filter_map do |doc|
    next if File.basename(doc) == '_TEMPLATE.md'

    link = Pathname(doc).relative_path_from(Pathname(File.dirname(index))).to_s
    "#{doc} is not linked from #{index}" unless text.include?("](#{link}")
  end
end
exit 0 if missing.empty?

warn "Docs missing from their index:\n#{missing.map { |m| "- #{m}" }.join("\n")}\n" \
     'Add the entries, or ask the user if a doc should stay unlisted.'
exit 2
