require 'net/http'

module Linux
  module Packager

    def self.packages
      @@packages = Linux::Config.profile_settings['packages']
    end

    def self.fetch_files
      self.packages.each do | file_name |
        
        package = self.load_package(file_name)
        puts "Loading package #{file_name}... "
        self.fetch_file(package)
      end
    end

    def self.load_package(file_name)
      return Linux::Config.load_package(file_name)
    end

    def self.fetch_file(package)
      file_name = package['info']['filename']
      file_path = "#{SOURCES}/#{file_name}"
      download_url = package['info']['download']
      
      unless File.exists?(file_path) && Digest::MD5.hexdigest(File.read(file_path)) == package['info']['md5']
        puts "Downloading package #{file_name}... "
        self.download_source(file_name, download_url)
      else
        puts "Previsolly downloaded package #{file_name}... Skip"
      end
    end

    def self.download_source(file_name, download_url)
    
      url = URI.parse(download_url)
      res = Net::HTTP.start(url.host, url.port) do |http|
        source_file_name = open("#{SOURCES}/#{file_name}", "wb")
        begin
          http.request_get(url.path) do |resp|
            resp.read_body do |segment|
              source_file_name.write(segment)
            end
          end
        ensure
          source_file_name.close()
        end
      end
      
    end 
  
  end
end
