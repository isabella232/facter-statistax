class CommandLogger
  def initialize(log_folder, error_log_file, log_file = 'log.log')
    @log_folder = log_folder
    @log_file = log_file
    @errors_file = error_log_file
  end

  def log(data, log_file_name = nil)
    log_file = log_file_name.nil? ? @log_file : log_file_name
    append_to_file(data, log_file)
  end

  def log_error(data)
    append_to_file(data, @errors_file)
  end

  private

  def append_to_file(data, log_file_name)
    File.open("#{@log_folder}/#{log_file_name}.log", mode: 'a') do |file|
      file.write("\n#{data}\n")
    end
  end
end