
module Linux
  
  module Config
    
    
    
    def self.ok?
      self.load_basic_profile && self.load_profile
    end
 
    def self.load_package(file_name)
      file_path = "#{PACKAGES}/#{file_name}.yml"
      return YAML::load( File.open( file_path ) )
    end
 
    def self.load_profile(profile_name = 'KoshLinuxBasic')
      file_path = "#{PROFILES}/#{profile_name}.yml"
      self.profile_settings = YAML::load( File.open( file_path ) )
      return true
    end
 
    def self.load_basic_profile(linux_basic_name = 'LinuxBasic')

      linux_basic = "#{PROFILES}/#{linux_basic_name}.yml"
      self.linux_basic_settings = YAML::load( File.open( linux_basic ) )

      variables = self.linux_basic_settings['variables']

      puts "You may need correct set these environments variables before continue:"
      variables.each do | variable |
          puts "  export #{variable[0].upcase}=#{variable[1]}"
      end

      variables.each do | variable |
        unless ENV[variable[0].upcase] == variable[1]
          puts "Please run "
          puts "  export #{variable[0].upcase}=#{variable[1]}"
          return false
        end
      end
      return true
    end

    def self.profile_settings
      @@profile_settings
    end
    
    def self.profile_settings=(profile_settings)
      @@profile_settings=profile_settings
    end


    def self.linux_basic_settings
      @@linux_basic_settings
    end
    
    def self.linux_basic_settings=(linux_basic_settings)
      @@linux_basic_settings=linux_basic_settings
    end
    
  end

end


