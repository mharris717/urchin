require "test/unit"
require "fileutils"
require "#{File.dirname(__FILE__)}/helpers"
require "#{File.dirname(__FILE__)}/../lib/command"

module Urchin
  class CommandTestCase < Test::Unit::TestCase

    include TestHelpers

    class Urchin::Command
      attr_reader :args
    end

    def setup
      @old_dir = Dir.getwd
      Dir.chdir File.dirname(__FILE__)
    end

    def teardown
      Dir.chdir @old_dir
      old_teardown
    end

    def test_executing_a_command
      status = nil
      output = with_redirected_output do
        command = Command.create("echo", JobTable.new)
        command << "123"

        pid = fork do
          command.execute
        end
        pits, status = Process.waitpid2 pid
      end

      assert_equal "123", output.chomp
      assert_equal 0, status.exitstatus
    end

    def test_create
      assert_kind_of Command, Command.create("ls", JobTable.new)
      assert_kind_of Builtins::Cd, Command.create("cd", JobTable.new)
    end

    def test_to_s
      command = Command.create("sleep", JobTable.new)
      command << "20"
      assert_equal "sleep 20", command.to_s
    end

    def test_appending_an_argument_returns_self
      command = Command.create("sleep", JobTable.new)
      assert_equal command, command << "--hello"
      assert_equal 1, command.args.size
    end

    def test_redirecting_stdout_to_a_file
      command = Command.create("echo", JobTable.new) << "123"
      command.add_redirect(STDOUT, "stdout_testfile", "w")

      pid = fork { command.execute }
      pid, status = Process.waitpid2 pid

      assert_equal "123\n", File.read("stdout_testfile")
      assert_equal 0, status.exitstatus
    ensure
      FileUtils.rm("stdout_testfile", :force => true)
    end

    def test_redirecting_stdout_to_a_file_appending
      command = Command.create("echo", JobTable.new) << "123"
      command.add_redirect(STDOUT, "stdout_testfile", "a")

      pid = fork { command.execute }
      Process.wait pid

      # should create the file and write to it
      assert_equal "123\n", File.read("stdout_testfile")

      pid = fork { command.execute }
      pid, status = Process.waitpid2 pid

      # should have appended to the file
      assert_equal "123\n123\n", File.read("stdout_testfile")
      assert_equal 0, status.exitstatus
    ensure
      FileUtils.rm("stdout_testfile", :force => true)
    end

    def test_redirecting_stderr_to_stdout
      command = Command.create("./stdout_stderr_writer", JobTable.new) << "this is out" << "this is err"
      command.add_redirect(STDOUT, "stdout_testfile", "w")
      command.add_redirect(STDERR, STDOUT, "w")

      pid = fork { command.execute }
      pid, status = Process.waitpid2 pid

      assert_match /this is out\n/, File.read("stdout_testfile")
      assert_match /this is err\n/, File.read("stdout_testfile")
      assert_equal 0, status.exitstatus
    ensure
      FileUtils.rm("stdout_testfile", :force => true)
    end

    def test_redirecting_a_file_to_stdin
      command = Command.create("./stdin_writer", JobTable.new)
      command.add_redirect(STDIN, "stdin_testfile", "r")
      command.add_redirect(STDOUT, "stdout_testfile", "w")

      pid = fork { command.execute }
      pid, status = Process.waitpid2 pid

      assert_match /this is in\n/, File.read("stdout_testfile")
      assert_equal 0, status.exitstatus
    ensure
      FileUtils.rm("stdout_testfile", :force => true)
    end

    def test_executing_command_that_does_not_exist
      command = Command.create("/this/does/not/exist", JobTable.new)
      command.add_redirect(STDERR, "stderr_testfile", "w")

      pid = fork { command.execute }
      pid, status = Process.waitpid2 pid

      assert_equal "Command not found: /this/does/not/exist\n", File.read("stderr_testfile")
      assert_equal 127, status.exitstatus
    ensure
      FileUtils.rm("stderr_testfile", :force => true)
    end

    def test_set_command_local_environment_variables
      command = Command.create("./env_var_writer", JobTable.new)
      command.add_redirect(STDOUT, "stdout_testfile", "w")
      command.environment_variables = { "LETTERS" => "ABC" }

      pid = fork { command.execute }
      pid, status = Process.waitpid2 pid

      assert_equal "ABC\n", File.read("stdout_testfile")
    ensure
      FileUtils.rm("stdout_testfile", :force => true)
    end
  end
end
