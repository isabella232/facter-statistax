# frozen_string_literal: true

require 'benchmark'
require 'open3'

if ARGV[0].to_s == 'false'
  if Gem.win_platform?
    facter_dir = 'C:/Program Files/Puppet Labs/Puppet/puppet/bin'
    ENV['PATH'] = "#{facter_dir}#{File::PATH_SEPARATOR}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
    require "#{facter_dir}/libfacter.so"
  else
    require '/opt/puppetlabs/puppet/lib/libfacter.so'
  end
elsif Gem.win_platform?
  require 'C:\Program Files\Puppet Labs\Puppet\puppet\lib\ruby\gems\2.5.0\gems\facter-2.5.5-x64-mingw32\lib\facter.rb'
else
  require 'facter'
end

time = Benchmark.realtime do
  if ARGV[1] == 'all'
    Facter.to_hash
  else
    Facter.value(ARGV[1])
  end
end

puts time
