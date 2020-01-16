# frozen_string_literal: true

test_name 'Install facter statistax' do
  agents.each do |agent|
    gem_c = gem_command(agent)
    on agent, "#{gem_c} install -f facter-statistax"
  end
end
