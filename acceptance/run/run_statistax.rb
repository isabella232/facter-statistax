# frozen_string_literal: true

require 'pathname'
test_name 'Run facter statistax' do
  agents.each do |agent|
    is_gem = ENV['IS_GEM'] || 'false'
    home_dir = on(agent, 'pwd').stdout.chop
    step 'Run facter statistax' do
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
      host_dir = File.join(Pathname.new(File.expand_path('..', __dir__)), "log_dir/#{agent['platform']}")

      out_dir = if is_gem == 'true'
                  File.join(host_dir, 'gem')
                else
                  File.join(host_dir, 'cpp')
                end
      scp_from agent, "#{home_dir}/log/output.json", out_dir
    end
  end
end
