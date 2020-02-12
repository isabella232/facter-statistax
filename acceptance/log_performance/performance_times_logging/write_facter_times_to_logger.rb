require_relative 'table_logging_utils'

class WriteFacterTimesToLogger
  RULE_RANGE = RangeInTable.new(1, 2, 100, 1000)

  def initialize(logger, facter_columns)
    @log_writer = logger
    @columns_each_fact = facter_columns
  end

  def write_to_logs(times_to_log)
    return if times_to_log.empty?

    @performance_times = times_to_log
    create_platform_page
    page_names = @log_writer.name_and_path_of_pages # done to get pages that are newly created
    @performance_times.keys.each do |platform|
      puts "\nWriting results for platform #{platform}\n"
      facts_order_in_table, page_is_new = create_title_rows(platform, page_names[platform])
      write_performance_times(facts_order_in_table, platform)
      add_conditional_formatting(page_is_new, page_names, platform, RULE_RANGE)
    end
  end

  private

  def create_platform_page
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
    # fact names occupy @columns_per_fact cells, so just the last one has the fact name, the rest are empty
    new_facts_row_with_spaces = new_facts.flat_map { |fact_name| [''] * (@columns_each_fact.size - 1) << fact_name }

    if new_facts.empty?
      puts 'No new fact names to add.'
    else
      # write new fact names from the second column (the first one is reserved for the date) if the page is empty,
      # or after the last fact name
      new_facts_append_range = RangeInTable.new(stored_facts.size + 1, 0, nil, 0)

      puts 'Adding fact names.'
      @log_writer.add_row_with_merged_cells(new_facts_row_with_spaces, platform, page_location, new_facts_append_range)
      puts 'Adding facter types and gem time increase.'
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
    facter_types_row = @columns_each_fact * (number_of_facts_to_add / @columns_each_fact.size)
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
        row.concat([''] * @columns_each_fact.size) # skip values for missing fact
      else
        populate_data_row(fact, platform, row)
      end
    end
    puts 'Appending performance times.'
    # range is for the first cell where data should be added on the sheet. If that cell is not empty, the new values will be
    # appended under it, where possible.
    @log_writer.write_to_page([row], platform, RangeInTable.new(0, 2, nil, 2))
  end

  def populate_data_row(fact, platform, row)
    cpp_fact = @performance_times[platform][fact][@columns_each_fact[0]]
    gem_fact = @performance_times[platform][fact][@columns_each_fact[1]]
    gem_percentage_increase = (gem_fact - cpp_fact) / cpp_fact * 100

    row << cpp_fact
    row << gem_fact
    row << format('%<time_difference>.2f', time_difference: gem_percentage_increase)
  end

  def add_conditional_formatting(page_is_new, page_names, platform, rule_range)
    return unless page_is_new

    success_message = 'Added rule to highlight gem run time increased over 100%!'
    rule = ConditionRule.greater_than(100, rule_range)
    @log_writer.format_range_by_condition(Color.new(1), page_names[platform], rule, rule_range, success_message)
  end
end