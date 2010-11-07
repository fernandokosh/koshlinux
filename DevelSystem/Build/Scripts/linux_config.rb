require 'yaml'

class Config  
  @@config = {}

  def ok?
    load_profile
  end
  
  def load_package(file_name)
    file_path = "#{KoshLinux::PACKAGES}/#{file_name}.yml"
    return YAML::load( File.open( file_path ) )
  end
  
  def load_profile(profile_name = 'KoshLinuxBasic')
    file_path = "#{KoshLinux::PROFILES}/#{profile_name}.yml"
    self.profile_settings = YAML::load( File.open( file_path ) )
    return true
  end
  
  def profile_settings
    @@config['profile_settings']
  end
  
  def profile_settings=(profile_settings)
    puts "Profile  ==> #{profile_settings['profile'].inspect}"
    puts "Packages ==> #{profile_settings['packages'].inspect}"
    puts "System   ==> #{profile_settings['system'].inspect}"
    puts "<=== END PROFILE ===>"
    @@config['profile_settings'] = profile_settings
  end

  def linux_basic_settings
    @@config['linux_basic_settings']
  end

  def linux_basic_settings=(linux_basic_settings)
    puts "YYY======> #{linux_basic_settings.inspect}"
    @@config['linux_basic_settings']=linux_basic_settings
  end
end
