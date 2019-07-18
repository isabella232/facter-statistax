# frozen_string_literal: true

# frozen_tring_literal: true

module FacterStatistax
  module Executors
    module Executor
      class << self
        def execute
          verify_file
          obj = JSON.parse(::File.read(CONFIG_FILE), object_class: OpenStruct)
          obj.each do |test_suite|
            FacterStatistax.logger.info("Begin test run: #{test_suite.test_run}")
            FacterStatistax.logger.info("Facter is gem? #{Common::GemDiscovery.gem?}")
            test_suite.runs.each do |run|
              run_executor(run)
            end
          end
        end

        private

        def verify_file
          raise(_('Please define config file!')) unless ::File.exist?(CONFIG_FILE)
        end

        def run_executor(run)
          FacterStatistax.logger.info("Number of repetitions: #{run.repetitions}")
          TestRunExecutor.new(run).execute
        end
      end
    end
  end
end
