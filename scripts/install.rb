#!/usr/bin/env ruby
# frozen_string_literal: true

# Connect a nested learning-agent toolkit to its host repository.
#
# Run from any directory after placing the toolkit inside a repository:
#
#   ruby learning-agent/scripts/install.rb
#   ruby learning-agent/scripts/install.rb --repo /path/to/repository

require "optparse"
require "pathname"

START_MARKER = "<!-- learning-agent:start -->"
END_MARKER = "<!-- learning-agent:end -->"

class InstallError < StandardError; end

def learning_agent_block(toolkit_path)
  <<~MARKDOWN.chomp
    #{START_MARKER}
    ## Learning Agent

    This repository uses mentor-led learning. Before handling implementation,
    planning, debugging, or code review, read and follow
    `#{toolkit_path}/AGENTS.md`. Treat `#{toolkit_path}/` as the toolkit root and
    this file's directory as the host repository root.
    #{END_MARKER}
  MARKDOWN
end

def nested_toolkit_path(repo_root, toolkit_root)
  relative = toolkit_root.relative_path_from(repo_root)
  first_part = relative.each_filename.first

  if relative.to_s == "." || first_part == ".."
    raise InstallError, "The learning-agent folder must be inside the host repository."
  end

  relative.to_s
rescue ArgumentError
  raise InstallError, "The learning-agent folder must be inside the host repository."
end

def updated_agents(existing, block)
  starts = existing.scan(START_MARKER).length
  ends = existing.scan(END_MARKER).length
  marked_block = /#{Regexp.escape(START_MARKER)}.*?#{Regexp.escape(END_MARKER)}/m

  unless starts == ends && starts <= 1 && (starts.zero? || existing.match?(marked_block))
    raise InstallError, "AGENTS.md has incomplete or duplicate learning-agent markers."
  end

  return existing.sub(marked_block, block) if starts == 1

  separator = if existing.empty? || existing.end_with?("\n\n")
                ""
              elsif existing.end_with?("\n")
                "\n"
              else
                "\n\n"
              end

  "#{existing}#{separator}#{block}\n"
end

def install_learning_agent(repo_root:, toolkit_root:, out: $stdout)
  repo_root = Pathname.new(repo_root).expand_path.cleanpath
  toolkit_root = Pathname.new(toolkit_root).expand_path.cleanpath

  raise InstallError, "Host repository not found: #{repo_root}" unless repo_root.directory?
  raise InstallError, "#{repo_root} is not a Git repository root." unless repo_root.join(".git").exist?
  raise InstallError, "Toolkit AGENTS.md not found: #{toolkit_root}" unless toolkit_root.join("AGENTS.md").file?

  toolkit_path = nested_toolkit_path(repo_root, toolkit_root)
  agents_path = repo_root.join("AGENTS.md")
  existing = agents_path.file? ? agents_path.read : ""
  content = updated_agents(existing, learning_agent_block(toolkit_path))

  if content == existing
    out.puts "Learning Agent is already connected in #{agents_path}."
  else
    agents_path.write(content)
    out.puts "Connected #{toolkit_path}/ to #{agents_path}."
  end

  agents_path
end

def main(argv, out: $stdout, err: $stderr)
  options = {}
  parser = OptionParser.new do |config|
    config.banner = "Usage: ruby learning-agent/scripts/install.rb [--repo PATH]"
    config.on("--repo PATH", "Host repository root (defaults to the toolkit parent)") do |path|
      options[:repo] = path
    end
  end
  parser.parse!(argv)
  raise InstallError, parser.banner unless argv.empty?

  toolkit_root = Pathname.new(__dir__).join("..").expand_path.cleanpath
  repo_root = options[:repo] || toolkit_root.parent
  install_learning_agent(repo_root: repo_root, toolkit_root: toolkit_root, out: out)
  0
rescue InstallError, OptionParser::ParseError => e
  err.puts e.message
  1
end

exit(main(ARGV)) if __FILE__ == $PROGRAM_NAME
