class KoshLinux
  KOSH_LINUX_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '/..')) unless defined?(KOSH_LINUX_ROOT)
  PROFILES = "#{KOSH_LINUX_ROOT}/Profiles"
  WORK = "#{KOSH_LINUX_ROOT}/Work"
  PACKAGES = "#{KOSH_LINUX_ROOT}/Depot/Recipes"
  SOURCES = "#{KOSH_LINUX_ROOT}/Depot/Sources"
  TOOLS = "#{WORK}/tools"
  LOGS = "#{WORK}/logs"

  def initialize
    [WORK, SOURCES, TOOLS, LOGS].each do |folder|
      puts "Creating #{folder}" && FileUtils.mkdir_p(folder) unless File.exist?(folder)
    end
    puts "Need create /tools symbolic links" && system("sudo ln -sv #{WORK}/tools /") unless File.exist?('/tools')
  end

  def config
    require 'linux_config'
    @@config = Config.new
  end

  def packager
    require 'linux_packager'
    @@packager = Packager.new
    @@packager.config = @@config
    @@packager
  end

  def cleaner(options)
    require 'cleaner'
    Cleaner.clean(options)
  end
end
