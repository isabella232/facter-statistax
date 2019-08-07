# frozen_string_literal: true

# frozen_tring_literal: true

module FacterStatistax
  module Executors
    module Executor
      class << self
        def execute
          facter_version = Common::VersionDiscovery.facter_version?
          json_writer = Common::OutputWriter.instance

          read_config_file.each do |test_suite|
            json_writer.write_test_suite(facter_version, test_suite.test_run)
            log_information(facter_version, test_suite.test_run)
            test_suite.runs.each do |run|
              run_executor(run)
            end
          end
          json_writer.write
        end

        private

        def read_config_file
          raise('Please define config file!') unless ::File.exist?(CONFIG_FILE)

          JSON.parse(::File.read(CONFIG_FILE), object_class: OpenStruct)
        end

        def log_information(facter_version, suite_name)
          logger.info("Begin test run: #{suite_name}")
          logger.info("Facter version: #{facter_version}")
        end

        def run_executor(run)
          logger.info("Number of repetitions: #{run.repetitions}")
          TestRunExecutor.new(run).execute
        end

        def logger
          FacterStatistax.logger
        end
      end
    end
  end
end
