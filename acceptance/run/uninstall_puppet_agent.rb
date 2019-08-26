# frozen_string_literal: true

test_name 'Uninstall puppet' do
  agents.each do |agent|
    remove_puppet_on(agent)
  end
end
