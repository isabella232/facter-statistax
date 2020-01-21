require_relative 'logger_types/google_sheets'
require_relative 'file_folder_utils'
require_relative 'json_reader'
require_relative 'position_in_table'

class LogPerformanceTimes
  @@log_files_per_platform = 2
  @@facter_types = ['cpp', 'gem']

  def initialize(log_dir_path, log_writer)
    @log_dir_path = log_dir_path
    @log_writer = log_writer
    @performance_times = {}
  end

  def populate_logs
    extract_performance_times_hash
    write_to_logs
  end

  def extract_performance_times_hash
    FileFolderUtils.get_sub_folder_path(@log_dir_path).each do |platform|
      json_file_paths = FileFolderUtils.get_subfile_paths_by_type("#{@log_dir_path}/#{platform}", 'json')
      if json_file_paths.length != @@log_files_per_platform
        puts "Something went wrong with logs for platform #{platform}. Skipping it!"
        next
      end
      results = get_times_for_platform(platform, json_file_paths)
      @performance_times[platform] = results unless results.empty?
    end
  end

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
    normalize(platform_times)
  end

  def parse_performance_log(data)
    results = {}
    data_hash = data[0] #the performance data is stored inside a list
    return [{}, ''] if data_hash['facter_gem?'].nil? or data_hash['facts'].nil?

    facter_type = data_hash['facter_gem?'] == 'true' ? 'gem' : 'cpp'
    data_hash['facts'].each do |fact|
      results[fact['name']] = fact['average']
    end
    [results, facter_type]
  end

  def normalize(platform_times)
    normalized_times = {}
    platform_times.each do |facter_type, fact|
      fact.each do |fact_name, time|
        normalized_times[fact_name] ||= {}
        normalized_times[fact_name].merge!(facter_type => time)
      end
    end
    add_nil_for_missing_values(normalized_times)
  end

  def add_nil_for_missing_values(platform_times)
    platform_times.each do |fact_name, facter_type_times|
      facter_type_times['gem'] = nil if facter_type_times['gem'].nil?
      facter_type_times['cpp'] = nil if facter_type_times['cpp'].nil?
    end
  end

  def write_to_logs()
    create_missing_platform_pages
    page_names = @log_writer.name_and_path_of_pages
    @performance_times.keys.each do |platform|
      table_header = create_table_header(platform, page_names[platform])
      add_performance_times(table_header, platform)
    end
  end

  def create_missing_platform_pages
    logged_platforms = @log_writer.name_and_path_of_pages.keys
    extracted_platforms = @performance_times.keys
    @log_writer.create_pages(extracted_platforms - logged_platforms)
  end

  def create_table_header(platform, page_id)
    title_position = PositionInTable.new(0,0,nil,0)
    current_table_header = @log_writer.get_values_from_page(platform, title_position)[0] #we need just the first row from the row list
    new_facts = @performance_times[platform].keys - current_table_header
    facts_row_with_spaces = new_facts.flat_map{|x| ['', x]}[0..-1]
    title_append_position = PositionInTable.new(current_table_header.size == 1 ? 0 : current_table_header.size + 1,0,nil,0)
    @log_writer.add_header([facts_row_with_spaces], platform, page_id, title_append_position)
    facter_types_row = @@facter_types * (facts_row_with_spaces.size / @@facter_types.size)
    if current_table_header.empty?
      facter_types_row = ['Date'].concat(facter_types_row)
      facter_types_position = PositionInTable.new(0,1,nil,1)
    else
      facter_types_position = PositionInTable.new(title_append_position.start_column, 1, nil, 1)
    end
    @log_writer.write_to_page([facter_types_row], platform, facter_types_position)
    all_facts = current_table_header + facts_row_with_spaces
    all_facts.delete('')
    all_facts
  end

  def add_performance_times(table_header, platform)
    row = [Time.now.to_i]
    table_header.each do |fact|
      if @performance_times[platform][fact].nil?
        row.concat(['', ''])
      else
        row << @performance_times[platform][fact][@@facter_types[0]]
        row << @performance_times[platform][fact][@@facter_types[1]]
      end
    end
    @log_writer.write_to_page([row], platform, PositionInTable.new(0,2,nil,2))
  end
end