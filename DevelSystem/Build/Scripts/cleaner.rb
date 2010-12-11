require 'fileutils'

class Cleaner
  def Cleaner.clean_sources
    puts "Cleaning up sources: "
    Dir.glob("#{KoshLinux::SOURCES}/*") do |folder|
      puts "Removing folder: #{folder}"
      FileUtils.rm_rf(folder)
    end
  end

  def Cleaner.clean_work
    puts "Cleaning up work: "
    Dir.glob("#{KoshLinux::WORK}/*") do |folder|
      unless (folder == KoshLinux::TOOLS || folder == KoshLinux::LOGS)
        puts "Removing folder: #{folder}"
        FileUtils.rm_rf(folder)
      end
    end
  end

  def Cleaner.clean_logs
    puts "Cleaning up logs: "
    Dir.glob("#{KoshLinux::LOGS}/*.out") do |file|
      puts "Removing file: #{file}"
      FileUtils.rm_rf(file)
    end
  end

  def Cleaner.clean_tools
    puts "Cleaning up tools: "
    Dir.glob("#{KoshLinux::TOOLS}/*") do |folder|
      puts "Removing folder: #{folder}"
      FileUtils.rm_rf(folder)
    end
    Dir.glob([KoshLinux::WORK, '.status', '**', 'ok'].join('/')) do |file|
      puts "Removing status: #{file}"
      FileUtils.rm_rf(file)
    end         
  end

  def Cleaner.clean_ccache
    folder = "#{KoshLinux::WORK}/.ccache"
    puts "Cleaning up .ccache: #{folder}"
    FileUtils.rm_rf(folder) if File.exist?(folder)
    exit(0)
  end
  
  def Cleaner.clean_all
    clean_tools
    clean_logs
    clean_work
  end

  def Cleaner.clean_all_sources
    clean_all
    clean_sources
  end

  def Cleaner.clean(options)
    option = options[:clear]
    option = "work" if option.nil? # Default option
    puts "Cleaner: #{option}"
    send("clean_#{option}")
    puts "Cleanup: end."
  end
end
