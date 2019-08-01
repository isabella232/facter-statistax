# frozen_string_literal: true

# frozen_tring_literal: true

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
        repetitions.times do
          time = Benchmark.measure do
            system("#{FACTER_BIN_PATH} #{fact} > /dev/null")
          end
          log_time(fact, time)
        end
      end

      def log_time(fact, time)
        FacterStatistax.logger.info("For #{fact} facts it took:")
        FacterStatistax.logger.info("#{format('%.2f', time.real)}s")
      end
    end
  end
end
