require_relative 'logger_types/google_sheets'
require_relative 'utils'
require 'date'

class LogPerformanceTimes
  LOG_FILES_PER_PLATFORM = 2
  FACT_COLUMNS = ['cpp', 'gem', 'gem increase %']
  SPREADSHEET_ID = '1giARlXsBSGhxIWRlThV8QfmybeAfaBrNRzdr9C0pvPw'

  def initialize(statistax_logs_folder)
    @log_parser = LogParser.new(statistax_logs_folder, LOG_FILES_PER_PLATFORM)
    @log_writer = WriteTimesToLogger.new(GoogleSheets.new(SPREADSHEET_ID), FACT_COLUMNS)
  end

  def populate_logs_for(platform_name)
    performance_times = @log_parser.extract_performance_times_hash(platform_name)
    @log_writer.write_to_logs(performance_times)
  end
end

class LogParser
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
  def initialize(logger, facter_columns)
    @log_writer = logger
    @facter_columns = facter_columns
  end

  def write_to_logs(times_to_log)
    @performance_times = times_to_log
    create_platform_page_if_missing
    page_names = @log_writer.name_and_path_of_pages # done to get pages that are newly created
    rule_range = RangeInTable.new(1, 2, 100, 1000)
    @performance_times.keys.each do |platform|
      puts "\nWriting results for platform #{platform}\n"
      facts_order_in_table, page_is_new = create_title_rows(platform, page_names[platform])
      write_performance_times(facts_order_in_table, platform)
      add_conditional_formatting(page_is_new, page_names, platform, rule_range)
    end
  end

  private

  def add_conditional_formatting(page_is_new, page_names, platform, rule_range)
    if page_is_new
      success_message = 'Added rule to highlight gem run time increased over 100%!'
      rule = ConditionRule.greater_than(100, rule_range)
      @log_writer.format_range_by_condition(Color.new(1), page_names[platform], rule, rule_range, success_message)
    end
  end

  def create_platform_page_if_missing
    logged_platforms = @log_writer.name_and_path_of_pages.keys
    platform_name = @performance_times.keys[0]
    if logged_platforms.include?(platform_name)
      puts 'Platform page already created.'
    else
      @log_writer.create_page(platform_name)
    end
  end

  def create_title_rows(platform, page_location)
    # fact names are stored on the first table row
    stored_facts = @log_writer.get_rows_from_page(platform, RangeInTable.new(0, 0, nil, 0))[0]

    new_facts = @performance_times[platform].keys - stored_facts
    # fact names occupy FACT_COLUMNS.size cells, so just the last one has the fact name, the rest are empty
    new_facts_row_with_spaces = new_facts.flat_map { |fact_name| [''] * (@facter_columns.size - 1) << fact_name }

    if new_facts.empty?
      puts 'No new fact names to add.'
    else
      # write new fact names from the second column (the first one is reserved for the date) if the page is empty,
      # or after the last fact name
      new_facts_append_range = RangeInTable.new(stored_facts.size + 1, 0, nil, 0)

      puts 'Adding fact names.'
      @log_writer.add_row_with_merged_cells(new_facts_row_with_spaces, platform, page_location, new_facts_append_range)
      puts 'Adding facter types.'
      create_facter_type_row(new_facts_row_with_spaces.size, new_facts_append_range.start_column, platform, stored_facts.empty?)
    end
    [get_new_facts_order(new_facts_row_with_spaces, stored_facts), stored_facts.empty?]
  end

  def get_new_facts_order(new_facts_row_with_spaces, stored_facts)
    stored_facts_order = stored_facts + new_facts_row_with_spaces
    stored_facts_order.delete('')
    stored_facts_order
  end

  def create_facter_type_row(number_of_facts_to_add, write_from_column, platform, add_date_title)
    facter_types_row = @facter_columns * (number_of_facts_to_add / @facter_columns.size)
    if add_date_title
      facter_types_row = ['Date'].concat(facter_types_row)
      facter_types_range = RangeInTable.new(0, 1, nil, 1)
    else
      facter_types_range = RangeInTable.new(write_from_column, 1, nil, 1)
    end
    @log_writer.write_to_page([facter_types_row], platform, facter_types_range)
  end

  def write_performance_times(facts_order_list, platform)
    row = [DateTime.now.strftime("%d/%m/%Y %H:%M")] # adding timestamp
    facts_order_list.each do |fact|
      if @performance_times[platform][fact].nil?
        row.concat([''] * @facter_columns.size) # skip values for missing fact
      else
        cpp_fact = @performance_times[platform][fact][@facter_columns[0]]
        gem_fact = @performance_times[platform][fact][@facter_columns[1]]
        gem_percentage_increase = (gem_fact - cpp_fact) / cpp_fact * 100

        row << cpp_fact
        row << gem_fact
        row << format('%<time_difference>.2f', time_difference: gem_percentage_increase)
      end
    end
    puts 'Appending performance times.'
    # range is for the first cell where data should be added on the sheet. If that cell is not empty, the new values will be
    # appended under it, where possible.
    @log_writer.write_to_page([row], platform, RangeInTable.new(0, 2, nil, 2))
  end
end