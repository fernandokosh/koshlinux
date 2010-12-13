class KoshLinux
  KOSH_LINUX_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '/..')) unless defined?(KOSH_LINUX_ROOT)
  PROFILES = "#{KOSH_LINUX_ROOT}/Profiles"
  WORK = "#{KOSH_LINUX_ROOT}/Work"
  PACKAGES = "#{KOSH_LINUX_ROOT}/Depot/Recipes"
  SOURCES = "#{KOSH_LINUX_ROOT}/Depot/Sources"
  TOOLS = "/tools"
  LOGS = "#{WORK}/logs"
  require 'linux_config'
  require 'linux_packager'
  attr_reader :config, :packager, :options
  
  def initialize(options)
    @options = options
    @config = Config.create
    @packager = Packager.create
    @packager.config = @config
    @packager.options = @options

    [WORK, SOURCES, "#{WORK}/tools", LOGS].each do |folder|
      puts "Creating #{folder}" && FileUtils.mkdir_p(folder) unless File.exist?(folder)
    end
    unless File.symlink?('/tools') && File.readlink('/tools') == File.join(WORK, 'tools')
      puts "Need create /tools symbolic links"
      system("sudo ln -sfv #{WORK}/tools /")
    end
  end

  def cleaner
    require 'cleaner'
    Cleaner.clean(@options)
  end

  def KoshLinux.timer
    raise "I need a code to run, put it on block" unless block_given?
    @@start = Time.now
    puts "Starting at: #{@@start}"
    yield
    @@end = Time.now
    puts "Ended at: #{@@end}"
    @@elapsed = @@end - @@start
    @@humanized_time = [[60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map{ |count, name|
      if @@elapsed > 0
        @@elapsed, n = @@elapsed.divmod(count)
        "#{n.to_i} #{name}"
      end
    }.compact.reverse.join(' ')
    puts "Elapsed Time: #{@@humanized_time}"
  end
end
