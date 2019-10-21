# frozen_string_literal: true

module FacterStatistax
  module Executors
    class TestRunExecutor
      def initialize(run)
        @fact = run.fact
        @repetitions = run.repetitions
      end

      attr_reader :fact, :repetitions

      def execute
        sum = sum_for_each_repetition do
          time, _status = Open3.capture2("ruby \"#{SCRIPTS_DIR}/benchmark_script.rb\" #{IS_GEM} #{fact}")
          log_time(fact, time)
          time.to_f
        end
        Common::OutputWriter.instance.write_run(fact, sum / repetitions)
      end

      private

      def sum_for_each_repetition
        sum = 0
        repetitions.times do
          time = yield
          sum += time
        end
        sum
      end

      def log_time(fact, time)
        FacterStatistax.logger.info("For #{fact} facts it took:")
        FacterStatistax.logger.info("#{format('%<time>.2f', time: time)}s")
      end
    end
  end
end
