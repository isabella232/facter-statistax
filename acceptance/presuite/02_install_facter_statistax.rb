# frozen_string_literal: true

test_name 'Install facter statistax' do
  agents.each do |agent|
    gem_c = gem_command(agent)
    on agent, "#{gem_c} install -f facter-statistax"
    gem_path = (on agent, "#{gem_c} which statistax").stdout.chop
    gem_path = gem_path.match(/.*[0-9]+./)

    script = File.join(Pathname.new(File.expand_path('../..', __dir__)), 'scripts/benchmark_script.rb')
    scp_to agent, script, "#{gem_path}/scripts"
  end
end
