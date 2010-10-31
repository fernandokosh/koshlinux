
module Linux
  
  
  
  module Config
    
    def self.ok?
      if self.load_basic_profile
        puts 'Configuration OK'
      else
        puts 'Configuration Error'
      end
    end
 
    def self.load_basic_profile(linux_basic_name = 'LinuxBasic')

      linux_basic = "#{PROFILES}/#{linux_basic_name}.yml"
      linux_basic_settings = YAML::load( File.open( linux_basic ) )

      variables = linux_basic_settings['variables']

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
    
  end

end


