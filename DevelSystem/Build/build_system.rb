#!/usr/bin/ruby -IScripts -wv

require 'optparse'
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ./build_system.rb [options]"

  clear_description=<<END_OF_DESCRIPTION

        Clean the system before build with (TYPE):
          tools: Clear builder tools folder
          logs: Clear build logs
          work: Clear work folder (default)
          sources: Clear the sources files
          all: Clear all except the sources
          all_sources: Clear all files and source. with this, you got a clean repository
END_OF_DESCRIPTION

  opts.on("-d", "--debug", "Show commands executed on EnvironmentBox") do
    options[:debug] = true
  end

  options[:keep_work] = true # Default for keep work folder
  opts.on("--no-keep", "--no-keep-work", "Remove unpacked folder before compile") do |k|
    options[:keep_work] = false
  end
  
  opts.on("-c [TYPE]", "--clear [TYPE]", clear_description) do |clear|
    options[:clear] = clear
  end
end.parse!

require 'kosh_linux'
KoshLinux.timer do
  linux = KoshLinux.new(options)
  linux.cleaner if options.include?(:clear)
  if linux.config.ok?
    puts "Starting up..."
    linux.packager.build_all
  end
end
