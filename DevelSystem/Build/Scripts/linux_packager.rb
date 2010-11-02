require 'net/http'
require 'fileutils'

class Packager

  def config=(config)
    @@config=config
  end

  def config
    @@config
  end
  
  def build_all
    package_list.each do | file_name |
      package = load_package(file_name)
      build_package(package)
    end      
  end
  
  def build_package(package, operation="run")
    check_dependencies(package)
    fetch_file(package)
    unpack_file(package)
    unless operation=="source_only"
      configure_package(package)
      make_package(package)
      make_install_package(package)
    end
  end
  
  def check_dependencies(source_package)
    puts source_package['info']['name'].inspect
    puts source_package['dependencies'].inspect unless source_package['dependencies'].nil? 
    source_package['dependencies']['source_only'].each do |dependency|
      package = load_package(dependency)
      build_package(package, "source_only")
    end unless source_package['dependencies'].nil? || source_package['dependencies']['source_only'].nil?
  end

  def fetch_files
    package_list.each do | file_name |
      package = load_package(file_name)
      fetch_file(package)
    end
  end

  def configure_package(package)
    
    unpack_folder = package['info']['unpack_folder']
    unpack_path = "#{WORK}/#{unpack_folder}"
    compile_folder = package['info']['compile_folder']
    compile_path = "#{WORK}/#{compile_folder}"
    
    if File.exists?(compile_path)
      FileUtils.cd(compile_path)
      compile_path = "../#{unpack_folder}"
    else
      FileUtils.cd(unpack_path)
      compile_path = "."
    end
    
    options = package['build']['options']
    target = "--target=#{config.linux_basic_settings['variables']['linux_target']}"
    prefix = "--prefix=/tools"
    #eprefix = "--exec-prefix=/usr"
    configure = system("#{compile_path}/configure #{target} #{prefix} #{options}")

    FileUtils.cd(KOSH_LINUX_ROOT)
    return configure
  end

  def make_package(package)
    unpack_folder = "#{WORK}/#{package['info']['unpack_folder']}"
    compile_folder = "#{WORK}/#{package['info']['compile_folder']}"

    if File.exists?(compile_folder)
      FileUtils.cd(compile_folder)
    else
      FileUtils.cd(unpack_folder)
    end

    make = system("make")
    FileUtils.cd(KOSH_LINUX_ROOT)
    return make
  end

  def make_install_package(package)
    unpack_folder = "#{WORK}/#{package['info']['unpack_folder']}"
    compile_folder = "#{WORK}/#{package['info']['compile_folder']}"

    if File.exists?(compile_folder)
      FileUtils.cd(compile_folder)
    else
      FileUtils.cd(unpack_folder)
    end

    make_install = system("make install")
    FileUtils.cd(KOSH_LINUX_ROOT)
    return make_install
  end

  def unpack_file(package)
    file_name = package['info']['filename']
    archive_path = "#{SOURCES}/#{file_name}"
    pack_folder = "#{WORK}/#{package['info']['pack_folder']}"
    unpack_folder = "#{WORK}/#{package['info']['unpack_folder']}" unless package['info']['unpack_folder'].nil?
    unpack_folder ||= pack_folder
    compile_folder = "#{WORK}/#{package['info']['compile_folder']}"
    packer = package['info']['packer']
    
    unless package['info']['compile_folder'].nil?
      puts "Creating compile folder: #{compile_folder}"
      FileUtils.mkdir_p(compile_folder)
    end
    
    if File.exists?(unpack_folder)
      puts "Using previsouly unpacked #{unpack_folder}"
      return true
    end
    
    puts "Unpacking #{file_name}"
    
    case packer
      when 'tar.bz2' then
        puts "Archive type: tar.bz2"
        unpack_tar_bz2(archive_path)
      when 'tar.gz' then
        puts "Archive type: tar.gz"
        unpack_tar_gz(archive_path)
      else
        puts "Error: Unreconized packer type: #{packer}"
        exit
    end
    unless pack_folder == unpack_folder
      puts "Renaming file: #{pack_folder} => #{unpack_folder}"
      FileUtils.cd(WORK)
      FileUtils.mv(pack_folder, unpack_folder) 
      FileUtils.cd(KOSH_LINUX_ROOT)
    end
  end
  
  def unpack_tar_bz2(file_path)
    FileUtils.cd(WORK)
    system("tar -xjf #{file_path}")
    FileUtils.cd(KOSH_LINUX_ROOT)
  end

  def unpack_tar_gz(file_path)
    FileUtils.cd(WORK)
    system("tar -xzf #{file_path}")
    FileUtils.cd(KOSH_LINUX_ROOT)
  end

  def load_package(file_name)
    return config.load_package(file_name)
  end

  def fetch_file(package)
    file_name = package['info']['filename']
    file_path = "#{SOURCES}/#{file_name}"
    download_url = package['info']['download']
      
    unless File.exists?(file_path) && Digest::MD5.hexdigest(File.read(file_path)) == package['info']['md5']
      puts "Downloading package #{file_name}... "
      self.download_source(file_name, download_url)
    else
      puts "Previously downloaded package #{file_name}... Skip"
    end
  end

  def package_list     
    @@packages = Config.new().profile_settings['packages']
  end

  def download_source(file_name, download_url)
   
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

