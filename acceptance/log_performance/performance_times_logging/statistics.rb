# frozen_string_literal: true

require_relative 'google_sheets'
require_relative 'table_logging_utils'
require_relative '../configuration'

def platform_sheet_names(platforms, sheets)
  platform_sheets = {}
  platforms.each do |platform_type, regexes|
    platform_sheets[platform_type] = []
    regexes.each do |regex|
      platform_sheet_names = sheets.filter { |name, _| name if name =~ /#{regex}/ }.keys
      platform_sheets[platform_type].concat(platform_sheet_names)
    end
  end
  platform_sheets
end

def initialize_result_hashes(platforms)
  platforms.keys.each do |platform|
    PLATFORM_TYPE_TIMES[platform] = {}
    VERSIONS.each do |version|
      PLATFORM_TYPE_TIMES[platform][version] = {}
      PLATFORM_TYPE_TIMES[platform][version][:to_hash] = []
      PLATFORM_TYPE_TIMES[platform][version][:facts] = []

      PLATFORM_SLOWEST[platform] = {}
      PLATFORM_SLOWEST[platform][:facts] = []
      PLATFORM_SLOWEST[platform][:to_hash] = []
    end
  end
end

def store_all_times(comparison_rows, main_rows, platform_type)
  if comparison_rows.size == 6
    #select facter 4 fact actual run times
    VERSIONS.each_with_index do |version, i|
      (0..1).each do |run_time|
        PLATFORM_TYPE_TIMES[platform_type][version][:facts].concat(comparison_rows[run_time * 3 + i][0..-4].select.with_index { |_, i| ((i + 1) % 3).zero? })
        PLATFORM_TYPE_TIMES[platform_type][version][:to_hash] << comparison_rows[run_time * 3 + i][-2]

        if i == 2
          PLATFORM_SLOWEST[platform_type][:facts] << comparison_rows[run_time * 3 + i][1..-4].select.with_index { |_, i| (i + 1) % 3 != 0 }
          PLATFORM_SLOWEST[platform_type][:to_hash] << comparison_rows[run_time * 3 + i][-3..-2]
        end
      end
    end
  end

  main_rows.each do |row|
    PLATFORM_TYPE_TIMES[platform_type][:ver_main][:facts].concat(row.select.with_index { |_, i| ((i + 1) % 3).zero? })
    PLATFORM_TYPE_TIMES[platform_type][:ver_main][:to_hash] << row[-2]

    PLATFORM_SLOWEST[platform_type][:facts] << row[1..-4].select.with_index { |_, i| (i + 1) % 3 != 0 }
    PLATFORM_SLOWEST[platform_type][:to_hash] << row[-3..-2]
  end
end

def store_all_times_aix(comparison_rows, main_rows, platform_type)
  if comparison_rows.size == 3
    #select facter 4 fact actual run times
    VERSIONS.each_with_index do |version, i|
      PLATFORM_TYPE_TIMES[platform_type][version][:facts].concat(comparison_rows[i][0..-4].select.with_index { |_, i| ((i + 1) % 3).zero? })
      PLATFORM_TYPE_TIMES[platform_type][version][:to_hash] << comparison_rows[i][-2]
    end
  end
end

def calculate_averages
  PLATFORM_TYPE_TIMES.each do |_, versions|
    versions.each do |_, times|
      if times[:facts].empty?
        times[:avg_facts] = 0
        times[:avg_to_hash] = 0
      else
        times[:avg_facts] = (times[:facts].map(&:to_f).sum / times[:facts].size.to_f).round(3)
        times[:avg_to_hash] = (times[:to_hash].map(&:to_f).sum / times[:to_hash].size.to_f).round(3)
      end
    end
  end
end

def calculate_each_fact_averages
  averages_hash = {}
  PLATFORM_SLOWEST.each do |platform_type, times|
    averages_hash[platform_type] = {}
    times.each do |fact, row_arrays|
      averages = []
      (0..row_arrays[0].size - 1).each do |value_index|
        avg = 0
        (0..row_arrays.size - 1).each do |row_index|
          avg += row_arrays[row_index][value_index].to_f
        end
        averages << (avg / row_arrays.size.to_f).round(5)
      end
      averages_hash[platform_type][fact] = averages
    end
  end
  averages_hash
end

def add_fact_time(ordered, platform_type, rank, ranking, times)
  facter_4_time = ordered[rank]
  facter_4_index = times[:facts].find_index(facter_4_time)
  fact_name = FACTS[facter_4_index / 2]
  ranking[platform_type][fact_name] = []
  ranking[platform_type][fact_name] << times[:facts][facter_4_index - 1]
  ranking[platform_type][fact_name] << times[:facts][facter_4_index]
end

def calculate_slowest_5(averages_hash)
  ranking = {}
  averages_hash.each do |platform_type, times|
    ranking[platform_type] = {}
    ordered = times[:facts].select.with_index { |_, i| ((i + 1) % 2).zero? }.sort.reverse

    (0..4).each do |rank|
      add_fact_time(ordered, platform_type, rank, ranking, times)
    end
    add_fact_time(ordered, platform_type, ordered.size - 1, ranking, times)
    ranking[platform_type]['all'] = averages_hash[platform_type][:to_hash]
  end
  ranking
end

def arrange_averages
  values = {
    v35: [],
    v36: [],
    main: []
  }
  PLATFORM_TYPE_TIMES.each do |platform_type, versions|
    # puts "Platform #{platform_type}\n"
    # versions.each do |version, times|
    #   puts "Version #{version}"
    #   puts "Average all: #{times[:avg_facts]}"
    #   puts "Average tu_hash: #{times[:avg_to_hash]}"
    # end
    values[:v35] << versions[:ver_35][:avg_facts]
    values[:v35] << versions[:ver_35][:avg_to_hash]
    values[:v36] << versions[:ver_36][:avg_facts]
    values[:v36] << versions[:ver_36][:avg_to_hash]
    values[:main] << versions[:ver_main][:avg_facts]
    values[:main] << versions[:ver_main][:avg_to_hash]
  end
  values
end

def arrange_fact_averages(ranking)
  values = []
  ranking.each do |platform, facts|
    facts.each_with_index do |fact, index|
      values[index] ||= []
      values[index] << fact[0]
      values[index].concat(fact[1])
    end
  end
  values
end

ENV['GOOGLE_APPLICATION_CREDENTIALS'] = '/Users/andrei.filipovici/projects/facter-statistax-performance/acceptance/google_sheets_credentials.json'

platforms =
  { windows_old: %w[win-2012 windows-2012 windows-2016],
    windows_new: %w[windows-2019 windows-10],
    sles: %w[sles],
    ubuntu: %w[ubuntu],
    debian: %w[debian],
    fedora: %w[fedora],
    centos: %w[el-6],
    redhat: %w[el-7 el-8 redhat-fips],
    osx: %w[osx],
    solaris: %w[solaris],
    aix: %w[aix]
  }

FACTS = %w[aio_agent_version augeas	disks	dmi	facterversion	filesystems	hypervisors	identity is_virtual	kernel kernelmajversion	kernelrelease	kernelversion	load_averages	memory	networking	os	path processors ruby	solaris_zones	ssh	system_uptime	timezone	virtual	zfs_featurenumbers	zfs_version	zpool_featurenumbers zpool_version]
NR_OF_FACTS = FACTS.size

worksheet = GoogleSheets.new(Configuration::SPREADSHEET_ID)
sheets = worksheet.name_and_path_of_pages
PLATFORM_TYPE_TIMES = {}
PLATFORM_SLOWEST = {}
VERSIONS = %i[ver_35 ver_36 ver_main]

initialize_result_hashes(platforms)
platform_sheets = platform_sheet_names(platforms, sheets)
platform_sheets.each do |platform_type, sheet_name|
  sheet_name.each do |name|
    rows = worksheet.get_rows_from_page_with_string_range(name, 'A50:CM150')
    comparison_rows = rows.select { |row| row[0] =~ %r!28/09/2020|29/09/2020! }
    last_comparison_index = rows.find_index(comparison_rows[-1])
    main_rows = rows[last_comparison_index + 1..-1]

    store_all_times(comparison_rows, main_rows, platform_type)
    store_all_times_aix(comparison_rows, main_rows, platform_type) if platform_type == :aix
  end
end

# calculate_averages
# values = arrange_averages
# worksheet.write_to_page(values.values, 'Statistics', RangeInTable.new(1, 2, 22, 3))

averages = calculate_each_fact_averages
ranking = calculate_slowest_5(averages)
values = arrange_fact_averages(ranking)
worksheet.write_to_page(values, 'Statistics', RangeInTable.new(0, 8, 32, 17))
