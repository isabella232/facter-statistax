# frozen_string_literal: true

require 'pathname'
require 'logger'
require 'fileutils'
require 'open3'
require 'json'
require_relative '../lib/logger'

ROOT_DIR      = Pathname.new(File.expand_path('..', __dir__)) unless defined?(ROOT_DIR)
LOG_DIR       = File.join(Dir.getwd, 'log')
SCRIPTS_DIR   = ROOT_DIR.join('scripts')
CONFIG_FILE   = ARGV[0] || ''
IS_GEM        = ARGV[1] || 'false'

def load_files(*dirs)
  dirs.each { |dir| Dir[ROOT_DIR.join(dir)].each { |file| require file } }
end

load_files(
  'lib/common/*.rb',
  'lib/executors/*.rb'
)
