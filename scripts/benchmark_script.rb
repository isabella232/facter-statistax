# frozen_string_literal: true

require 'benchmark'
require 'open3'

def facter_path(gems_path)
  ruby_version = Dir.entries(gems_path).select { |file| file =~ /[0-9]+.[0-9]+.[0-9]+/ }
  facter_ng_path = File.join(gems_path, ruby_version, 'gems')
  facter_ng_version = Dir.entries(facter_ng_path).select { |file| file =~ /facter-4/ }
  File.join(facter_ng_path, facter_ng_version, 'lib', 'facter.rb')
end

if ARGV[0].to_s == 'false'
  if Gem.win_platform?
    facter_dir = 'C:/Program Files/Puppet Labs/Puppet/puppet/bin'
    ENV['PATH'] = "#{facter_dir}#{File::PATH_SEPARATOR}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
    require "#{facter_dir}/libfacter.so"
  else
    require '/opt/puppetlabs/puppet/lib/libfacter.so'
  end
elsif Gem.win_platform?
  require facter_path('C:/Program Files/Puppet Labs/Puppet/puppet/lib/ruby/gems')
else
  require facter_path('/opt/puppetlabs/puppet/lib/ruby/gems')
end

time = Benchmark.realtime do
  if ARGV[1] == 'all'
    Facter.to_hash
  else
    Facter.value(ARGV[1])
  end
end

puts time
