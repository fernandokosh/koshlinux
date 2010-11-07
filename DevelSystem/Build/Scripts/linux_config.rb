class Config
  require 'yaml'
  private_class_method :new
  @@config = nil

  def Config.create
    @@config = new unless @@config
    @@config
  end

  def initialize(profile_name = 'KoshLinuxBasic')
    file_path = "#{KoshLinux::PROFILES}/#{profile_name}.yml"
    @config = {}
    @recipe_profile = YAML::load(File.open(file_path))
  end
  
  def ok?
    load_profile
  end
  
  def load_profile()
    return true unless @recipe_profile.nil?
  end
  
  def profile_settings
    @recipe_profile
  end
  
  def profile_settings=(profile_settings)
    puts "Profile  ==> #{recipe_profile['profile'].inspect}"
    puts "Packages ==> #{recipe_profile['packages'].inspect}"
    puts "System   ==> #{recipe_profile['system'].inspect}"
    puts "<=== END PROFILE ===>"
    @config['profile_settings'] = recipe_profile
  end

end
