require_relative 'beaker'

class NSPooler < Beaker
  def initialize(platforms, user_home_path, env_vars, logger)
    super(platforms, user_home_path, env_vars, logger)
  end

  def run_test_on_all_platforms
    @platforms.each do |platform, platform_template|
      begin
        @current_platform = platform
        next unless get_nspooler_vm(platform_template)

        test_sequence
      rescue FailedCommand
        destroy_environment
        next
      end
    end
  end

  def create_vm_hosts_file
    log_run_command("beaker-hostgenerator #{get_beaker_platform_name(@current_platform, @nspooler_host_name)} > hosts.yaml")
  end

  def destroy_environment
    super
    log_run_command("curl -H X-AUTH-TOKEN:VmPoolerAuthToken -X POST -d '' --url https://nspooler-service-prod-1.delivery.puppetlabs.net/api/v1/maint/reset/#{@nspooler_host_name}")
  end

  private

  def get_nspooler_vm(platform_template)
    provisioned_vm = make_request_for_vm(platform_template)
    if provisioned_vm['ok'] == true
      @nspooler_host_name = provisioned_vm[platform_template]['hostname']
      true
    else
      @logger.log_error("No VM available for #{@current_platform}")
      false
    end
  end

  def make_request_for_vm(platform_template)
    get_vm_response = log_run_command("curl --fail --silent --show-error -H X-AUTH-TOKEN:VmPoolerAuthToken -X POST -d '{\"#{platform_template}\":1}' --url https://nspooler-service-prod-1.delivery.puppetlabs.net/api/v1/host/")
    JSON.parse(get_vm_response.gsub('=>', ':'))
  rescue
    return { 'ok': false }
  end

  def get_beaker_platform_name(platform, nsPooler_host_name)
    #because of how packaging for agent is made we need to lie beaker about aix version. If we have a version 7, we need
    # to tell it, it's running on version 6
    beaker_platform = if platform.include?('aix7')
                        platform.sub(/aix7[1-2]/, 'aix61')
                      else
                        platform
                      end
    "#{beaker_platform}\\{hypervisor=none\\,hostname=#{nsPooler_host_name}\\}"
  end
end

