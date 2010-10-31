#!/usr/bin/ruby

require 'yaml'
require 'md5'
require 'Scripts/kosh_linux'



KOSH_LINUX_ROOT = "#{File.dirname(__FILE__)}" unless defined?(KOSH_LINUX_ROOT)
PROFILES = "#{KOSH_LINUX_ROOT}/Profiles"
WORK = "#{KOSH_LINUX_ROOT}/Work"
PACKAGES = "#{KOSH_LINUX_ROOT}/Depot/Recipes"
SOURCES = "#{KOSH_LINUX_ROOT}/Depot/Sources"


def print_echo(msg='')
  puts msg
end

linux = KoshLinux.new

if linux.config.ok?
  puts 'running...'
  linux.packager.fetch_files
end

