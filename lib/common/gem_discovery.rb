# frozen_string_literal: true

# frozen_tring_literal: true

module FacterStatistax
  module Common
    module GemDiscovery
      class << self
        def gem?
          stdout, _status = Open3.capture2(FACTER_BIN_PATH, '--version')
          /2\.[0-9]+\.[0-9]+/.match?(stdout)
        end
      end
    end
  end
end
