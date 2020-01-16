# frozen_string_literal: true

test_name 'Install facter gem' do
  agents.each do |agent|
    current_dir = Pathname.new(File.expand_path('..', __dir__))
    facter_ng_path = Dir.entries(current_dir).select { |file| file =~ /facter-ng-[0-9]+.[0-9]+.[0-9]+.gem/ }
    facter_gem = File.join(current_dir, facter_ng_path)
    home_dir = on(agent, 'pwd').stdout.chop

    scp_to agent, facter_gem, home_dir

    gem_c = gem_command(agent)
    on agent, "#{gem_c} uninstall facter-ng"
    on agent, "#{gem_c} install -f facter-ng-*.gem"
    if agent['platform'] =~ /windows/
      puppetbin_path = '"/cygdrive/c/Program Files (x86)/Puppet Labs/Puppet/puppet/bin":"/cygdrive/c/Program Files/Puppet Labs/Puppet/puppet/bin"'
      on agent, %( echo 'export PATH=$PATH:#{puppetbin_path}' > /etc/bash.bashrc )
    end
  end
end
