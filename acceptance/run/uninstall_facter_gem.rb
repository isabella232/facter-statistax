# frozen_string_literal: true

test_name 'Install facter gem' do
  agents.each do |agent|
    gem_c = gem_command(agent)
    on agent, "#{gem_c} uninstall -f facter -v #{ENV['GEM_VERSION']}"
  end
end
