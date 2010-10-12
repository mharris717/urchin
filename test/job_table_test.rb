require "test/unit"
require "fileutils"

require "#{File.dirname(__FILE__)}/helpers"
require "#{File.dirname(__FILE__)}/../lib/job"
require "#{File.dirname(__FILE__)}/../lib/command"

module Urchin
  class JobTableTestCase < Test::Unit::TestCase
    def setup
      @job_table = JobTable.new
    end

    def test_insert
      @job_table.insert Job.new(Command.create("ls", @job_table), @job_table)
      assert_equal 1, @job_table.jobs.size
    end

    def test_delete
      ls = Job.new(Command.create("ls", @job_table), @job_table)
      @job_table.insert ls
      pwd = Job.new(Command.create("pwd", @job_table), @job_table)
      @job_table.insert pwd

      assert_equal 2, @job_table.jobs.size
      @job_table.delete pwd
      assert_equal ls, @job_table.jobs[1]
    end

    def test_last_job
      ls = Job.new(Command.create("ls", @job_table), @job_table)
      @job_table.insert ls
      pwd = Job.new(Command.create("pwd", @job_table), @job_table)
      @job_table.insert pwd

      assert_equal pwd, @job_table.last_job
    end
  end
end