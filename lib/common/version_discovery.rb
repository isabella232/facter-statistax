# frozen_string_literal: true

module FacterStatistax
  module Common
    module VersionDiscovery
      class << self
        def facter_version?
          stdout, _status = Open3.capture2(FACTER_BIN_PATH, '--version')
          stdout.match(/[0-9]\.[0-9]+\.[0-9]+/)
        end
      end
    end
  end
end
