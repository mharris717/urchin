# Copyright (c) 2010 Mark Somerville <mark@scottishclimbs.com>
# Released under the GNU General Public License (GPL) version 3.
# See COPYING.

require "#{File.dirname(__FILE__)}/../lib/builtin"
require "#{File.dirname(__FILE__)}/../lib/job_table"

module Urchin
  module Builtins
    class Fg
      include Methods

      def valid_arguments?
        unless @arguments.empty?
          raise UrchinRuntimeError.new("Too many arguments.")
        end
      end

      def execute
        valid_arguments?
        if job = @job_table.jobs.last
          job.foreground!
        else
          raise UrchinRuntimeError.new("No current job.")
        end
      end
    end
  end
end
