require_relative 'logger_types/google_sheets'
require_relative 'file_folder_utils'
require_relative 'json_reader'
require_relative 'position_in_table'

class LogPerformanceTimes
  LOG_FILES_PER_PLATFORM = 2
  FACTER_TYPES = ['cpp', 'gem']
  SPREADSHEET_ID = '1giARlXsBSGhxIWRlThV8QfmybeAfaBrNRzdr9C0pvPw'

  def initialize(statistax_logs_folder)
    @log_parser = LogParser.new(statistax_logs_folder, LOG_FILES_PER_PLATFORM)
    @log_writer = WriteTimesToLogger.new(GoogleSheets.new(SPREADSHEET_ID), FACTER_TYPES)
  end

  def populate_logs
    performance_times = @log_parser.extract_performance_times_hash
    @log_writer.write_to_logs(performance_times)
  end
end

class LogParser
  def initialize(statistax_logs_folder, log_files_per_platform)
    @log_dir_path = statistax_logs_folder
    @log_files_per_platform = log_files_per_platform
    @performance_times = {}
  end

  def extract_performance_times_hash
    FileFolderUtils.get_sub_folder_path(@log_dir_path).each do |platform|
      json_file_paths = FileFolderUtils.get_subfile_paths_by_type("#{@log_dir_path}/#{platform}", 'json')
      if json_file_paths.length != @log_files_per_platform
        puts "Something went wrong with logs for platform #{platform}. Skipping it!"
        next
      end
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
    data_hash = data[0] #the performance data is stored inside a list

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

class WriteTimesToLogger
  def initialize(logger, facter_types)
    @log_writer = logger
    @facter_types = facter_types
  end

  def write_to_logs(times_to_log)
    @performance_times = times_to_log
    create_missing_platform_pages
    page_names = @log_writer.name_and_path_of_pages #done to get pages that are newly created
    @performance_times.keys.each do |platform|
      facts_order_in_table = create_title_rows(platform, page_names[platform])
      write_performance_times(facts_order_in_table, platform)
    end
  end

  private

  def create_missing_platform_pages
    logged_platforms = @log_writer.name_and_path_of_pages.keys
    extracted_platforms = @performance_times.keys
    @log_writer.create_pages(extracted_platforms - logged_platforms)
  end

  def create_title_rows(platform, page_location)
    #fact names are stored on the first table row
    stored_facts = @log_writer.get_rows_from_page(platform, PositionInTable.new(0, 0, nil, 0))[0]
    new_facts = @performance_times[platform].keys - stored_facts
    #fact names occupy 2 cells, so one of them is empty
    facts_row_with_spaces = new_facts.flat_map{|x| ['', x]}[0..-1]

    #write new fact names from the second column (the first one is reserved for the date) if the page is empty,
    # or after the last fact name
    new_facts_append_position = PositionInTable.new(stored_facts.size + 1,0,nil,0)

    puts 'Adding fact names.'
    @log_writer.add_row_with_merged_cells(facts_row_with_spaces, platform, page_location, new_facts_append_position)
    puts 'Adding facter types.'
    create_facter_type_row(facts_row_with_spaces.size, new_facts_append_position.start_column, platform, stored_facts.empty?)

    stored_facts_order = stored_facts + facts_row_with_spaces
    stored_facts_order.delete('')
    stored_facts_order
  end

  def create_facter_type_row(number_of_facts_to_add, write_from_column, platform, add_date_title)
    facter_types_row = @facter_types * (number_of_facts_to_add / @facter_types.size)
    if add_date_title
      facter_types_row = ['Date'].concat(facter_types_row)
      facter_types_position = PositionInTable.new(0, 1, nil, 1)
    else
      facter_types_position = PositionInTable.new(write_from_column, 1, nil, 1)
    end
    @log_writer.write_to_page([facter_types_row], platform, facter_types_position)
  end

  def write_performance_times(facts_order_list, platform)
    row = [Time.now.to_i] #adding timestamp
    facts_order_list.each do |fact|
      if @performance_times[platform][fact].nil?
        row.concat(['', '']) #skip values for missing fact
      else
        row << @performance_times[platform][fact][@facter_types[0]]
        row << @performance_times[platform][fact][@facter_types[1]]
      end
    end
    puts 'Adding performance times.'
    @log_writer.write_to_page([row], platform, PositionInTable.new(0,2,nil,2))
  end
end