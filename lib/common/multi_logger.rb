# frozen_string_literal: true

module FacterStatistax
  module Common
    class MultiLogger
      LEVELS = %i[debug info warn error fatal unknown].freeze

      LEVELS.each do |level|
        define_method(level) do |*args|
          targets.map { |target| target.send(level, *args) }
        end
      end

      def initialize(*targets)
        @targets = targets
      end

      private

      attr_reader :targets
    end
  end
end
