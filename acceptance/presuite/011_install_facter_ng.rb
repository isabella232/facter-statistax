# frozen_string_literal: true

test_name 'Install facter gem' do
  agents.each do |agent|
    facter_gem = File.join(Pathname.new(File.expand_path('..', __dir__)), 'facter-ng-0.0.10.gem')
    home_dir = on(agent, 'pwd').stdout.chop

    scp_to agent, facter_gem, home_dir

    gem_c = gem_command(agent)
    on agent, "#{gem_c} install -f facter-ng-0.0.10.gem"
    if agent['platform'] =~ /windows/
      puppetbin_path = '"/cygdrive/c/Program Files (x86)/Puppet Labs/Puppet/puppet/bin":"/cygdrive/c/Program Files/Puppet Labs/Puppet/puppet/bin"'
      on agent, %( echo 'export PATH=$PATH:#{puppetbin_path}' > /etc/bash.bashrc )
    end
  end
end
