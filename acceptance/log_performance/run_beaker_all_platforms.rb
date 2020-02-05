require 'open3'
require 'json'
require 'date'
require 'set'

class RunPerformanceOnAllPlatforms

  BEAKER_ENV_VARS = {'GOOGLE_APPLICATION_CREDENTIALS' => '/Users/andrei.filipovici/projects/google-sheets/Facter Performance History-99315759f0c6.json',
                     'IS_GEM' => 'true'}

  FACTER_NG_PROJECT_PATH = '/Users/andrei.filipovici/projects/facter-ng/'
  STATISTAX_ACCEPTANCE_FOLDER_PATH = '/Users/andrei.filipovici/projects/facter-statistax/acceptance/'
  FAILURES_FILE_PATH = '/Users/andrei.filipovici/projects/facter-statistax/acceptance/failure.log'
  LOGS_FOLDER_PATH = '/Users/andrei.filipovici/projects/facter-statistax/acceptance/cron_logs'
  USER_HOME_PATH = '/Users/andrei.filipovici/'
  NSPOOLER_PLATFORMS = {
      "aix61-POWER" => "aix-6.1-power",
      "aix71-POWER" => "aix-7.1-power",
      "aix72-POWER" => "aix-7.2-power",
      "redhat7-POWER" => "redhat-7.3-power8",
      "redhat7-AARCH64" => "centos-7-arm64",
      "sles12-POWER" => "sles-12-power8",
      "ubuntu1604-POWER" => "ubuntu-16.04-power8"
  }
  VMPOOLERP_PLATFORMS = [
      "centos6-32",
      "centos6-64",
      "centos8-64",
      "debian8-32",
      "debian8-64",
      "debian9-32",
      "debian9-64",
      "debian10-64",
      "fedora28-64",
      "fedora29-64",
      "fedora30-64",
      "fedora31-64",
      "osx1012-64",
      "osx1013-64",
      "osx1014-64",
      "redhat5-64",
      "redhat7-64",
      "redhatfips7-64",
      "redhat8-64",
      "sles11-32",
      "sles11-64",
      "sles12-64",
      "sles15-64",
      "solaris10-64",
      "solaris11-64",
      "solaris114-64",
      "ubuntu1404-32",
      "ubuntu1404-64",
      "ubuntu1604-32",
      "ubuntu1604-64",
      "ubuntu1804-64",
      "windows2008r2-64",
      "windows2012r2-64",
      "windows2016-64",
      "windows2019-64",
      "windows10ent-32",
      "windows10ent-64"
  ]

  def initialize
    @start_time = DateTime.now.strftime("%d-%m-%Y_%H:%M")
    @current_run_folder_path = "#{LOGS_FOLDER_PATH}/#{@start_time}"
    @platform = 'all'
    @error_lines = Set.new
  end

  def run_tests
    begin
      starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      create_directory(LOGS_FOLDER_PATH)
      create_directory(@current_run_folder_path)

      BEAKER_ENV_VARS['SHA'] = get_latest_agent_build_sha
      create_latest_facter_gem

      run_statistax_on_nsPooler
      run_statistax_on_vmPooler

      ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      append_to_log("Entire run took: #{(ending - starting) / 60} minutes.", 'all')
    rescue Exception => e
      error_message = e.message + "\n" + e.backtrace.inspect.gsub(', ', "\n")
      puts error_message
      append_to_log("\n\n#{@start_time}\n" + error_message, 'script_failure')
    end
  end

  def create_directory(name)
    Dir.mkdir(name) unless File.exists?(name)
  end

  def get_latest_agent_build_sha
    append_to_log('Get latest agent build SHA!', 'all', false)
    run_command('curl --fail --silent GET --url http://builds.delivery.puppetlabs.net/passing-agent-SHAs/puppet-agent-master')
  end

  def create_latest_facter_gem
    Dir.chdir(FACTER_NG_PROJECT_PATH) do
      append_to_log('Get latest changes in Facter-NG project.', 'all', false)
      run_command('git pull')
    end
    Dir.chdir(STATISTAX_ACCEPTANCE_FOLDER_PATH) do
      append_to_log('Build Facter-NG gem file.', 'all', false)
      run_command('bash build_facter_ng_gem.sh')
    end
  end

  def run_statistax_on_vmPooler
    VMPOOLERP_PLATFORMS.each do |platform|
      starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @platform = platform
      run_statistax_test_commands(platform)
      ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      append_to_log("Running time was: #{(ending - starting) / 60} minutes.")
    end
  end

  def run_statistax_test_commands(beaker_platform)
    Dir.chdir(STATISTAX_ACCEPTANCE_FOLDER_PATH) do
      # if an error happened and beaker destroy doesn't get called, the .beaker folder remains and it need to be deleted. Otherwise you get an error
      # saying the beaker parameters can't be parsed
      run_command("cd #{USER_HOME_PATH} && rm -rf .beaker")
      run_command(BEAKER_ENV_VARS, "beaker-hostgenerator #{beaker_platform} > hosts.yaml")
      run_command(BEAKER_ENV_VARS, 'beaker init -h hosts.yaml --options-file config/aio/options.rb')
      run_command(BEAKER_ENV_VARS, 'bundle exec beaker provision')
      run_command(BEAKER_ENV_VARS, 'bundle exec beaker exec pre-suite --pre-suite presuite/01_install_puppet_agent.rb,presuite/011_install_facter_ng.rb,presuite/02_install_facter_statistax.rb')
      run_command(BEAKER_ENV_VARS, 'bundle exec beaker exec run/run_statistax.rb')
      run_command('beaker destroy')
      log_all_error_lines
    end
  end

  def run_command(environment_variables = {}, command)
    output = ""
    Open3.popen2e(environment_variables, command) do |stdin, stdout_and_stderr, wait_thr|
      stdout_and_stderr.each do |line|
        output << line
        puts line
        check_line_for_errors(line)
      end
    end
    append_to_log("Running command: #{command}\nOutput:\n#{output}")
    output
  end

  def check_line_for_errors(line)
    errors_list = [
        'Retrying in',
        'No such file or directory',
        'command not found',
        'InvalidURIError',
        'Operation timed out',
        'ERROR'
    ]
    errors_list.each do |error|
      if line.include?(error)
        @error_lines << line[line.index(error)..] #extract content after run time details
      end
    end
  end

  def append_to_log(message, platform = nil, with_spaces = true)
    platform_log_file_path = if platform.nil?
                               "#{@current_run_folder_path}/#{@platform}.log"
                             else
                               "#{@current_run_folder_path}/#{platform}.log"
                             end

    File.open(platform_log_file_path, mode: 'a') do |file|
      if with_spaces == true
        file.write("\n\n#{message}\n\n")
      else
        file.write(message)
      end
    end
  end

  def run_statistax_on_nsPooler
    NSPOOLER_PLATFORMS.each do |platform, platform_template|
      starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @platform = platform
      provisioned_vm_hash = get_nsPooler_vm(platform, platform_template)
      if provisioned_vm_hash['ok'] == false
        next
      else
        nspooler_host_name = provisioned_vm_hash[platform_template]['hostname']
        run_statistax_test_commands(get_beaker_platform_name(platform, nspooler_host_name))
        append_to_log("Destroying nsPooler #{platform} VM!")
        run_command(BEAKER_ENV_VARS, "curl -H X-AUTH-TOKEN:VmPoolerAuthToken -X POST -d '' --url https://nspooler-service-prod-1.delivery.puppetlabs.net/api/v1/maint/reset/#{nspooler_host_name}")
      end
      ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      append_to_log("Running time was: #{(ending - starting) / 60} minutes.")
    end
  end

  def get_nsPooler_vm(platform, platform_template)
    append_to_log("Acquiring nsPooler #{platform} VM!")
    get_vm_response = run_command(BEAKER_ENV_VARS, "curl --fail --silent --show-error -H X-AUTH-TOKEN:VmPoolerAuthToken -X POST -d '{\"#{platform_template}\":1}' --url https://nspooler-service-prod-1.delivery.puppetlabs.net/api/v1/host/")
    JSON.parse(get_vm_response.gsub('=>', ':'))
  end

  def get_beaker_platform_name(platform, nsPooler_host_name)
    #because of how packaging for agent is made we need to lie beaker about aix version. If we have a version 7, we need
    # to tell it, it's running on a version 6
    beaker_platform = if platform.include?('aix7')
                        platform.sub(/aix7[1-2]/, 'aix61')
                      else
                        platform
                      end
    "#{beaker_platform}\\{hypervisor=none\\,hostname=#{nsPooler_host_name}\\}"
  end

  def log_all_error_lines
    current_platform = @platform
    unless @error_lines.empty?
      append_to_log("#{@start_time} Platform: #{current_platform}  Errors:\n#{@error_lines.to_a.join("\n")}\n", 'run_failures')
      @error_lines = Set.new
    end
    @platform = current_platform
  end
end

RunPerformanceOnAllPlatforms.new.run_tests