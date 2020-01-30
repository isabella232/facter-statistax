# frozen_string_literal: true

require 'open3'
require 'json'

ENV_VARS = {'SHA' => 'latest',
            'GOOGLE_APPLICATION_CREDENTIALS' => '/Users/andrei.filipovici/projects/google-sheets/Facter Performance History-99315759f0c6.json',
            'IS_GEM' => 'true'}

def run_statistax_on_vmPooler
  vmPoolerPlatforms = ["centos6-32", "centos6-64", "centos8-64", "debian8-32", "debian8-64", "debian9-32", "debian9-64", "debian10-64", "fedora28-64", "fedora29-64", "fedora30-64", "fedora31-64", "osx1012-64", "osx1013-64", "osx1014-64", "redhat5-64", "redhat7-64", "redhatfips7-64", "redhat8-64", "sles11-32", "sles11-64", "sles12-64", "sles15-64", "solaris10-64", "solaris11-64", "solaris114-64", "ubuntu1404-32", "ubuntu1404-64", "ubuntu1604-32", "ubuntu1604-64", "ubuntu1804-64", "windows2008r2-64", "windows2012r2-64", "windows2016-64", "windows2019-64", "windows10ent-32", "windows10ent-64"]
  vmPoolerPlatforms.each do |platform|
    run_statistax_test_commands(platform, true)
  end
end

def run_statistax_on_nsPooler
  nsPoolerPlatforms = { "aix61-POWER" => "aix-6.1-power", "aix71-POWER" => "aix-7.1-power", "aix72-POWER" => "aix-7.2-power", "redhat7-POWER" => "redhat-7.3-power8", "sles12-POWER" => "sles-12-power8", "ubuntu1604-POWER" => "ubuntu-16.04-power8" }

  nsPoolerPlatforms.each do |platform, platform_template|
    stdout = run_command(ENV_VARS, "curl -H X-AUTH-TOKEN:VmPoolerAuthToken -X POST -d '{\"#{platform_template}\":1}' --url https://nspooler-service-prod-1.delivery.puppetlabs.net/api/v1/host/")
    nsPooler_host_name = JSON.parse(stdout.gsub("=>", ":"))[platform_template]['hostname']

    run_statistax_test_commands("#{platform}\\{hypervisor=none\\,hostname=#{nsPooler_host_name}\\}", false)
    run_command(ENV_VARS, "curl -H X-AUTH-TOKEN:VmPoolerAuthToken -X POST -d '' --url https://nspooler-service-prod-1.delivery.puppetlabs.net/api/v1/maint/reset/#{nsPooler_host_name}")
  end
end

def run_statistax_test_commands(platform, run_provision)
  run_command(ENV_VARS, "beaker-hostgenerator #{platform} > hosts.yaml")
  run_command(ENV_VARS, "beaker init -h hosts.yaml --options-file config/aio/options.rb")
  run_command(ENV_VARS, "bundle exec beaker provision") if run_provision
  run_command(ENV_VARS, "bundle exec beaker exec pre-suite --pre-suite presuite/01_install_puppet_agent.rb,presuite/011_install_facter_ng.rb,presuite/02_install_facter_statistax.rb")
  run_command(ENV_VARS, "bundle exec beaker exec run/run_statistax.rb")
  run_command({}, "beaker destroy")
end

def run_command(environment_variables, command)
  stdout, status = Open3.capture2(environment_variables, command)
  puts stdout
  stdout
end

Open3.capture2("bash build_facter_ng_gem.sh")
Open3.capture2("cd /Users/andrei.filipovici/projects/facter-statistax/acceptance/")
run_statistax_on_vmPooler
run_statistax_on_nsPooler
