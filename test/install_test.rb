# frozen_string_literal: true

require "minitest/autorun"
require "pathname"
require "stringio"
require "tmpdir"
require_relative "../scripts/install"

class InstallTest < Minitest::Test
  def with_repository
    Dir.mktmpdir("learning-agent-install") do |directory|
      repo_root = Pathname.new(directory)
      repo_root.join(".git").mkdir
      toolkit_root = repo_root.join("learning-agent")
      toolkit_root.mkdir
      toolkit_root.join("AGENTS.md").write("# Learning rules\n")
      yield repo_root, toolkit_root
    end
  end

  def test_adds_bootstrap_without_replacing_existing_instructions
    with_repository do |repo_root, toolkit_root|
      agents_path = repo_root.join("AGENTS.md")
      agents_path.write("# Existing project instructions\n")

      install_learning_agent(repo_root: repo_root, toolkit_root: toolkit_root, out: StringIO.new)
      content = agents_path.read

      assert_includes content, "# Existing project instructions"
      assert_includes content, "`learning-agent/AGENTS.md`"
      assert_equal 1, content.scan(START_MARKER).length
    end
  end

  def test_install_is_idempotent
    with_repository do |repo_root, toolkit_root|
      output = StringIO.new

      install_learning_agent(repo_root: repo_root, toolkit_root: toolkit_root, out: output)
      first_content = repo_root.join("AGENTS.md").read
      install_learning_agent(repo_root: repo_root, toolkit_root: toolkit_root, out: output)

      assert_equal first_content, repo_root.join("AGENTS.md").read
      assert_includes output.string, "already connected"
    end
  end

  def test_rejects_a_toolkit_outside_the_repository
    Dir.mktmpdir("learning-agent-host") do |host_directory|
      Dir.mktmpdir("learning-agent-toolkit") do |toolkit_directory|
        repo_root = Pathname.new(host_directory)
        toolkit_root = Pathname.new(toolkit_directory)
        repo_root.join(".git").mkdir
        toolkit_root.join("AGENTS.md").write("# Learning rules\n")

        error = assert_raises(InstallError) do
          install_learning_agent(repo_root: repo_root, toolkit_root: toolkit_root, out: StringIO.new)
        end

        assert_includes error.message, "must be inside"
      end
    end
  end
end
