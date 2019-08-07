# frozen_string_literal: true

require 'pathname'
require 'benchmark'
require 'logger'
require 'fileutils'
require 'open3'
require 'json'
require_relative '../lib/logger'

ROOT_DIR      = Pathname.new(File.expand_path('..', __dir__)) unless defined?(ROOT_DIR)
LOG_DIR       = ROOT_DIR.join('log')
CONFIG_FILE   = ROOT_DIR.join('config.json')
FACTER_BIN_PATH = ARGV[0] || 'facter'

def load_files(*dirs)
  dirs.each { |dir| Dir[ROOT_DIR.join(dir)].each { |file| require file } }
end

load_files(
    'lib/common/*.rb',
    'lib/executors/*.rb'
)
