#!/usr/bin/ruby

KOSH_LINUX_ROOT = "#{File.dirname(__FILE__)}" unless defined?(KOSH_LINUX_ROOT)
PROFILES = "#{KOSH_LINUX_ROOT}/Profiles"
WORK = "#{KOSH_LINUX_ROOT}/Work"
PACKAGES = "#{KOSH_LINUX_ROOT}/Depot/Recipes"
SOURCES = "#{KOSH_LINUX_ROOT}/Depot/Sources"

require 'yaml'
require 'md5'
require 'Scripts/linux_config'
require 'Scripts/linux_build'
require 'Scripts/linux_packager'

def print_echo(msg='')
  puts msg
end

if Linux::Config.ok?
  puts 'run........'
  Linux::Packager.fetch_files
end

