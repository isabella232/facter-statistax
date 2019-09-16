# frozen_string_literal: true

require 'singleton'

module FacterStatistax
  module Common
    class OutputWriter
      include Singleton

      attr_reader :output, :facts, :test_run
      def initialize
        @output = []
        @test_run = {}
        @facts = []
      end

      def write
        test_run = @test_run.merge(facts: facts)
        output << test_run
        ::File.open(File.join(LOG_DIR, 'output.json'), 'w') do |file|
          file.write(JSON.pretty_generate(output))
        end
      end

      def write_test_suite(facter_version, test_run_name)
        @test_run = @test_run.merge(test_run_name: test_run_name, facter_gem?: facter_version)
      end

      def write_run(fact_name, time)
        fact_name = 'all' if fact_name.empty?
        fact = { 'name' => fact_name, 'average' => time.real }
        facts << fact
      end
    end
  end
end
