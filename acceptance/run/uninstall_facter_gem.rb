# frozen_string_literal: true

test_name 'Uninstall facter gem' do
  agents.each do |agent|
    gem_c = gem_command(agent)
    on agent, "#{gem_c} uninstall facter"
  end
end
