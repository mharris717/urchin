require "test/unit"
require "fileutils"
require "#{File.dirname(__FILE__)}/../helpers"
require "#{File.dirname(__FILE__)}/../../builtins/bg"

module Urchin
  module Builtins
    class BgTestCase < Test::Unit::TestCase
      include TestHelpers

      def test_validate_arguments
        jobs = Bg.new(JobTable.new)
        assert_nothing_raised { jobs.valid_arguments? }
        jobs << "--hello"
        assert_raises(UrchinRuntimeError) { jobs.valid_arguments? }
        jobs << "--hello"
        assert_raises(UrchinRuntimeError) { jobs.valid_arguments? }
      end

      def test_execute_with_no_backgrounded_jobs
        assert_raises(UrchinRuntimeError) { Bg.new(JobTable.new).execute }
      end

      def test_execute_no_arguments
        job_table = JobTable.new
        job = JobForTest.new
        job_table.insert job

        assert_nothing_raised { Bg.new(job_table).execute }
        assert job.background
      end

      def test_execute_with_job_id
        job_table = JobTable.new
        job = JobForTest.new
        job_table.insert job
        job_table.insert JobForTest.new

        bg = Bg.new(job_table) << "%1"

        assert_nothing_raised { bg.execute }
        assert job.background
      end
    end
  end
end
