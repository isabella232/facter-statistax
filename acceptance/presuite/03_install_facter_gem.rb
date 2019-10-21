# frozen_string_literal: true

test_name 'Install facter gem' do
  agents.each do |agent|
    gem_c = gem_command(agent)
    if ENV['GEM_VERSION']
      on agent, "#{gem_c} install -f facter-ng -v #{ENV['GEM_VERSION']}"
    else
      on agent, "#{gem_c} install -f facter-ng"
    end
  end
end
