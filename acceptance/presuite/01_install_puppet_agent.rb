# frozen_string_literal: true

test_name 'Install Puppet Agent Packages' do
  opts = {
    nightly_builds_url: ENV['NIGHTLY_BUILDS_URL'],
    dev_builds_url: ENV['DEV_BUILDS_URL'],
    puppet_agent_version: ENV['SHA'],
    puppet_collection: ENV['RELEASE_STREAM']
  }

  install_puppet_agent_on(hosts, opts)

  agents.each do |agent|
    on agent, puppet('--version')
    ruby = ruby_command(agent)
    on agent, "#{ruby} --version"

    log_dir = File.join(Pathname.new(File.expand_path('..', __dir__)), 'log_dir')
    FileUtils.mkdir_p(log_dir)
    host_dir = File.join(log_dir, agent['platform'])
    FileUtils.mkdir_p(host_dir)
  end
end
