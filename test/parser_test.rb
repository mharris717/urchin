require "test/unit"
require "fileutils"
require "#{File.dirname(__FILE__)}/helpers"
require "#{File.dirname(__FILE__)}/../lib/parser"
require "#{File.dirname(__FILE__)}/../lib/shell"

module Urchin
  class Job; attr_reader :commands, :start_in_background; end

  class Command
    attr_reader :executable, :args

    def ==(object)
      if object.class == Command
        if @executable == object.executable && @args == object.args
          return true
        end
      end
      false
    end
  end

  class Parser
    def setup(input)
      @input = StringScanner.new(input)
    end
  end

  class ParserTestCase < Test::Unit::TestCase
    def setup
      @parser = Parser.new(Shell.new)
    end

    def test_parse_word
      @parser.setup "ls"
      assert_equal "ls", @parser.parse_word
      @parser.setup "  --help"
      assert_equal "--help", @parser.parse_word
      @parser.setup "ls "
      assert_equal "ls", @parser.parse_word
      @parser.setup " -la "
      assert_equal "-la", @parser.parse_word
      @parser.setup '"/usr/bin/ls"'
      assert_equal "/usr/bin/ls", @parser.parse_word
      @parser.setup '"two words"'
      assert_equal "two words", @parser.parse_word
      @parser.setup '"a \"quote\" and stuff"'
      assert_equal 'a "quote" and stuff', @parser.parse_word
    end

    def test_simple_command
      jobs = @parser.jobs_from("ls")
      assert_equal 1, jobs.size
      assert_equal Command.new("ls"), jobs.first.commands.first

      jobs = @parser.jobs_from("ls -l -a")
      assert_equal 1, jobs.size
      assert_equal Command.new("ls") << "-l" << "-a", jobs.first.commands.first
    end

    def test_pipeline
      jobs = @parser.jobs_from("ls -l |head| wc -l")
      assert_equal 1, jobs.size
      assert_equal 3, jobs.first.commands.size
      assert_equal Command.new("ls") << "-l", jobs.first.commands.first
      assert_equal Command.new("head"), jobs.first.commands[1]
      assert_equal Command.new("wc") << "-l", jobs.first.commands.last
    end

    def test_background_job
      jobs = @parser.jobs_from("sleep 60 &")
      assert_equal 1, jobs.size
      assert_equal Command.new("sleep") << "60", jobs.first.commands.first
      assert jobs.first.start_in_background

      jobs = @parser.jobs_from("sleep 60&")
      assert_equal 1, jobs.size
      assert_equal Command.new("sleep") << "60", jobs.first.commands.first
      assert jobs.first.start_in_background
    end

    def test_multiple_jobs_semi_colon_seperator
      jobs = @parser.jobs_from("uptime; echo 123")
      assert_equal 2, jobs.size
      assert_equal 1, jobs.first.commands.size
      assert_equal Command.new("uptime"), jobs.first.commands.first
      assert_equal 1, jobs.last.commands.size
      assert_equal Command.new("echo") << "123", jobs.last.commands.first

      jobs = @parser.jobs_from("uptime ;echo 123")
      assert_equal 2, jobs.size
      assert_equal 1, jobs.first.commands.size
      assert_equal Command.new("uptime"), jobs.first.commands.first
      assert_equal 1, jobs.last.commands.size
      assert_equal Command.new("echo") << "123", jobs.last.commands.first
    end

    def test_multiple_jobs_with_background_job
      jobs = @parser.jobs_from("uptime & echo 123")
      assert_equal 2, jobs.size
      assert_equal 1, jobs.first.commands.size
      assert_equal Command.new("uptime"), jobs.first.commands.first
      assert_equal 1, jobs.last.commands.size
      assert_equal Command.new("echo") << "123", jobs.last.commands.first
      assert jobs.first.start_in_background
      assert !jobs.last.start_in_background
    end
  end
end