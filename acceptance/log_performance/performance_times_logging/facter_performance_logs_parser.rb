require_relative '../utils'

class FacterPerformanceLogsParser
  def initialize(statistax_logs_folder, log_files_per_platform)
    @log_dir_path = statistax_logs_folder
    @log_files_per_platform = log_files_per_platform
    @performance_times = {}
  end

  def extract_performance_times_hash(platform)
    json_file_paths = FileFolderUtils.get_sub_file_paths_by_type(File.join(@log_dir_path, platform), 'json')
    if json_file_paths.length != @log_files_per_platform
      puts "Something went wrong with logs for platform #{platform}. Skipping it!"
    else
      results = get_times_for_platform(platform, json_file_paths)
      @performance_times[platform] = results unless results.empty?
    end
    @performance_times
  end

  private

  def get_times_for_platform(platform, json_log_paths)
    platform_times = {}
    json_log_paths.each do |json_path|
      puts "Parsing log folder #{json_path}"
      content, facter_type = parse_performance_log(JSONReader.json_file_to_hash(json_path))
      if content.empty?
        puts "For platform #{platform}, failed to parse log #{json_path}!"
        puts "Skipping all logs for platform #{platform}!"
        return {}
      end
      platform_times[facter_type] = content
    end
    normalize_hash_structure(platform_times)
  end

  def parse_performance_log(data)
    results = {}
    data_hash = data[0] # the performance data is stored inside a list

    if data_hash['facter_gem?'].nil? || data_hash['facts'].nil?
      return [{}, '']
    end

    facter_type = data_hash['facter_gem?'] == 'true' ? 'gem' : 'cpp'
    data_hash['facts'].each do |fact|
      results[fact['name']] = fact['average']
    end
    [results, facter_type]
  end

  def normalize_hash_structure(platform_times)
    # hash is extracted as {cpp/gem => {fact_name => time}}
    # and is converted to {fact_name => {cpp/gem => time}}
    normalized_times = {}
    platform_times.each do |facter_type, fact|
      fact.each do |fact_name, time|
        normalized_times[fact_name] ||= {}
        normalized_times[fact_name][facter_type] = time
      end
    end
    normalized_times
  end
end