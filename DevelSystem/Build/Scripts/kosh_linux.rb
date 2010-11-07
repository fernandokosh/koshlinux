class KoshLinux
  KOSH_LINUX_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '/..')) unless defined?(KOSH_LINUX_ROOT)
  PROFILES = "#{KOSH_LINUX_ROOT}/Profiles"
  WORK = "#{KOSH_LINUX_ROOT}/Work"
  PACKAGES = "#{KOSH_LINUX_ROOT}/Depot/Recipes"
  SOURCES = "#{KOSH_LINUX_ROOT}/Depot/Sources"
  TOOLS = "#{WORK}/tools"
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

    [WORK, SOURCES, TOOLS, LOGS].each do |folder|
      puts "Creating #{folder}" && FileUtils.mkdir_p(folder) unless File.exist?(folder)
    end
    puts "Need create /tools symbolic links" && system("sudo ln -sv #{WORK}/tools /") unless File.exist?('/tools')
  end

  def cleaner
    require 'cleaner'
    Cleaner.clean(@options)
  end
end
