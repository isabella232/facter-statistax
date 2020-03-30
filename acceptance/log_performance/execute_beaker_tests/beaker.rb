require_relative '../custom_exceptions'
class Beaker

  def initialize(platforms, user_home_path, beaker_env_vars, logger)
    @platforms = platforms
    @user_home_path = user_home_path
    @beaker_env_vars = beaker_env_vars
    @logger = logger
  end

  def run_test_on_all_platforms
    @platforms.each do |platform|
      begin
        @current_platform = platform
        test_sequence
      rescue FailedCommand
        destroy_environment
      end
    end
  end

  def test_sequence
    time = TimedMethods.get_run_time{
      clean_beaker_home
      create_vm_hosts_file
      config_hosts_options
      provision
      install_agent_facter_statistax
      run_statistax_tests
      destroy_environment
    }
    @logger.log("Runtime was #{time} minutes.", @current_platform)
  end

  def clean_beaker_home
    # if an error happened and beaker destroy doesn't get called, the .beaker folder remains
    # and it need to be deleted. Otherwise you get an error saying the beaker parameters can't be parsed
    log_run_command("cd #{@user_home_path} && rm -rf .beaker")
  end

  def create_vm_hosts_file
    log_run_command("beaker-hostgenerator #{@current_platform} > hosts.yaml")
  end

  def config_hosts_options
    log_run_command('beaker init -h hosts.yaml --options-file config/aio/options.rb', 2)
  end

  def provision
    log_run_command('bundle exec beaker provision', 10)
  end

  def install_agent_facter_statistax
    log_run_command('bundle exec beaker exec pre-suite --pre-suite presuite/01_install_puppet_agent.rb,presuite/011_install_facter_ng.rb,presuite/02_install_facter_statistax.rb', 10)
  end

  def run_statistax_tests
    log_run_command('bundle exec beaker exec run/run_statistax.rb', 15)
  end

  def destroy_environment
    log_run_command('beaker destroy')
  end

  def log_run_command(command, timeout_minutes = 1)
    output = RunCommand.run_command(timeout_minutes, @beaker_env_vars, command)
    has_errors, errors = OutputParser.errors?(output)
    @logger.log("Running command: #{command}\n#{output}", @current_platform)

    return output unless has_errors

    @logger.log_error("On platform #{@current_platform},
                      running command:\n #{command}\ngot error:\n#{errors.join("\n")}")
    raise FailedCommand
  end
end