# frozen_string_literal: true

require 'pathname'
test_name 'Run facter statistax' do
  agents.each do |agent|
    is_gem = 'false'
    home_dir = on(agent, 'pwd').stdout.chop
    host_dir = File.join(Pathname.new(File.expand_path('..', __dir__)), "log_dir/#{agent['platform']}")

    step 'Run facter statistax for Cfacter' do
      content = ::File.read(File.join(Pathname.new(File.expand_path('..', __dir__)), 'config.json'))
      create_remote_file(agent, "#{home_dir}/config.json", content)
      if agent['platform'] =~ /windows/
        puppetbin_path = '"/cygdrive/c/Program Files (x86)/Puppet Labs/Puppet/puppet/bin":"/cygdrive/c/Program Files/Puppet Labs/Puppet/puppet/bin"'
        on agent, %( echo 'export PATH=$PATH:#{puppetbin_path}' > /etc/bash.bashrc )
        on agent, "statistax.bat config.json #{is_gem}"
      else
        on agent, "statistax #{home_dir}/config.json #{is_gem}"
      end
    end

    step 'Save output' do
      out_dir = File.join(host_dir, 'cpp')

      FileUtils.mkdir_p(out_dir)
      scp_from agent, "#{home_dir}/log/output.json", out_dir
    end

    step 'Run facter statistax for facter-ng' do
      is_gem = 'true'
      content = ::File.read(File.join(Pathname.new(File.expand_path('..', __dir__)), 'config.json'))
      create_remote_file(agent, "#{home_dir}/config.json", content)
      if agent['platform'] =~ /windows/
        puppetbin_path = '"/cygdrive/c/Program Files (x86)/Puppet Labs/Puppet/puppet/bin":"/cygdrive/c/Program Files/Puppet Labs/Puppet/puppet/bin"'
        on agent, %( echo 'export PATH=$PATH:#{puppetbin_path}' > /etc/bash.bashrc )
        on agent, "statistax.bat config.json #{is_gem}"
      else
        on agent, "statistax #{home_dir}/config.json #{is_gem}"
      end
    end

    step 'Save output to files' do
      out_dir = File.join(host_dir, 'cpp')

      FileUtils.mkdir_p(out_dir)
      scp_from agent, "#{home_dir}/log/output.json", out_dir
    end

    step 'Parse output to Google spreadsheet' do
      LogPerformanceTimes.new('../log_dir').populate_logs
    end
  end
end
