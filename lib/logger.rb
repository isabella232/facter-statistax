# frozen_string_literal: true

require_relative '../config/boot'

module FacterStatistax
  def self.logger
    FileUtils.mkdir_p(LOG_DIR) unless Dir.exist?(LOG_DIR)

    stdout_logger = Logger.new(STDOUT)
    stdout_logger.level = Logger::DEBUG

    file_logger = Logger.new(::File.open(LOG_DIR.join('statistax.log'), 'a'))
    file_logger.level = Logger::DEBUG

    @logger = Common::MultiLogger.new(file_logger, stdout_logger)
  end
end
