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
        fact.clear if fact == 'all'
        sum = sum_for_each_repetition do
          time = Benchmark.measure do
            _stdout, _status = Open3.capture2(FACTER_BIN_PATH, fact)
          end
          log_time(fact, time)
          time
        end
        Common::OutputWriter.instance.write_run(fact, sum / repetitions)
      end

      private

      def sum_for_each_repetition
        sum = 0
        repetitions.times do
          time = yield
          sum += time.real
        end
        sum
      end

      def log_time(fact, time)
        FacterStatistax.logger.info("For #{fact} facts it took:")
        FacterStatistax.logger.info("#{format('%.2f', time.real)}s")
      end
    end
  end
end
