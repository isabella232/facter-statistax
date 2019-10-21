# frozen_string_literal: true

test_name 'Run facter-ng gem' do
  agents.each do |agent|
    ruby = ruby_command(agent)
    if agent['platform'] =~ /windows/
      puppetbin_path = '"/cygdrive/c/Program Files (x86)/Puppet Labs/Puppet/puppet/bin":"/cygdrive/c/Program Files/Puppet Labs/Puppet/puppet/bin"'
      on agent, %( echo 'export PATH=$PATH:#{puppetbin_path}' > /etc/bash.bashrc )
    end
    # on agent, 'cd "C:\Program Files\Puppet Labs\Puppet\puppet\lib\ruby\gems\2.5.0\gems\facter-0.0.1"'
    on(agent, 'pwd').stdout.chop
    # on agent, ruby.to_s + ' "C:\Program Files\Puppet Labs\Puppet\puppet\lib\ruby\gems\2.5.0\gems\facter-0.0.1\bin\facter"'
    on agent, ruby.to_s + ' /opt/puppetlabs/puppet/lib/ruby/gems/2.5.0/gems/facter-0.0.1/bin/facter'
    on agent, 'facter'
  end
end
