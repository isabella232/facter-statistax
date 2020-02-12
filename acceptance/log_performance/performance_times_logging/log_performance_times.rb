require_relative 'facter_performance_logs_parser'
require_relative 'write_facter_times_to_logger'
require_relative 'google_sheets'
require_relative '../configuration'

class LogPerformanceTimes
  LOG_FILES_PER_PLATFORM = 2
  FACT_COLUMNS = ['cpp', 'gem', 'gem increase %']


  def initialize(statistax_logs_folder)
    @log_parser = FacterPerformanceLogsParser.new(statistax_logs_folder, LOG_FILES_PER_PLATFORM)
    @log_writer = WriteFacterTimesToLogger.new(GoogleSheets.new(Configuration::SPREADSHEET_ID), FACT_COLUMNS)
  end

  def populate_logs_for(platform_name)
    performance_times = @log_parser.extract_performance_times_hash(platform_name)
    @log_writer.write_to_logs(performance_times)
  end
end