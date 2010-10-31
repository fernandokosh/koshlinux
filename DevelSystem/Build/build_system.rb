#!/usr/bin/ruby

KOSH_LINUX_ROOT = "#{File.dirname(__FILE__)}" unless defined?(KOSH_LINUX_ROOT)

require 'yaml'
require 'Scripts/linux_config'
require 'Scripts/linux_build'
require 'Scripts/boot'

def print_echo(msg='')
  puts msg
end

print_echo('Kosh Linux build script.')
puts KOSH_LINUX_ROOT

Linux::Config.ok?
