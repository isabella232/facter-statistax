require 'benchmark'
require 'date'
require_relative 'vm_pooler'
require_relative 'ns_pooler'
require_relative 'run_command'
require_relative '../configuration'
require_relative '../utils'
require_relative 'command_logger'
require_relative 'output_parser'
require_relative '../custom_exceptions'

class TestAllPlatforms
  def initialize
    @logs_folder = "#{Configuration::LOGS_FOLDER_PATH}/#{DateTime.now.strftime("%d-%m-%Y_%H:%M")}"
    @logger = CommandLogger.new(@logs_folder, Configuration::SCRIPT_ERRORS_LOG_NAME, Configuration::PRE_TESTS_LOG_NAME)
    beaker_logger = CommandLogger.new(@logs_folder, Configuration::RUN_FAILS_LOG_NAME)
    @vmpooler = VMPooler.new(Configuration::VMPOOLERP_PLATFORMS,
                             Configuration::USER_HOME_PATH,
                             Configuration::BEAKER_ENV_VARS,
                             beaker_logger)
    @nspooler = NSPooler.new(Configuration::NSPOOLER_PLATFORMS,
                             Configuration::USER_HOME_PATH,
                             Configuration::BEAKER_ENV_VARS,
                             beaker_logger)
  end

  def run_tests
    time = TimedMethods.get_run_time {
      prepare_environment
      run_tests_on_vms
    }
    @logger.log("Runtime was #{time} minutes.")
  rescue FailedCommand
    exit
  rescue StandardError => e
    log_script_error(e)
  end

  private

  def prepare_environment
    FileFolderUtils.create_directories(@logs_folder)
    Configuration::BEAKER_ENV_VARS['SHA'] = get_latest_agent_sha
    get_latest_facter_ng_gem
  end

  def get_latest_agent_sha
    log_run_command('curl --fail --silent GET --url http://builds.delivery.puppetlabs.net/passing-agent-SHAs/puppet-agent-master')
  end

  def get_latest_facter_ng_gem
    Dir.chdir(Configuration::FACTER_NG_PROJECT_PATH) do
      update_facter_ng_main
      log_run_command('gem build facter.gemspec')
      log_run_command("mv *gem #{Configuration::STATISTAX_PROJECT_PATH}")
    end
  end

  def update_facter_ng_main
    log_run_command('git fetch --all')
    log_run_command('git reset --hard origin/main')
  end

  def run_tests_on_vms
    Dir.chdir(Configuration::STATISTAX_PROJECT_PATH) do
      @vmpooler.run_test_on_all_platforms
      @nspooler.run_test_on_all_platforms
    end
  end

  def log_run_command(command)
    output = RunCommand.run_command(command)
    has_errors, = OutputParser.errors?(output)
    if has_errors
      @logger.log("Command: #{command} had error:\n#{output}")
      raise FailedCommand
    else
      @logger.log("Running command: #{command}\n#{output}")
    end
    output
  end

  def log_script_error(e)
    error_message = e.message + "\n" + e.backtrace.inspect.gsub(', ', "\n")
    puts error_message
    @logger.log_error("#{@start_time}\n" + error_message)
  end
end

TestAllPlatforms.new.run_tests