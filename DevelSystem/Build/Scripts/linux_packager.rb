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
    fetch_file(package)
    unpack_file(package)
    check_dependencies(package)
    puts "build_package: configure start ::..:: "
    sleep(5)
    configure_package(package)
    puts "build_package: configure end ::..:: "
    sleep(5)
    if operation == "build" || operation == "run"
      make_package(package)
      puts "build_package:make_package: stop... "
      sleep(5)
    end
    
    unless operation=="source_only"
      make_install_package(package)
      puts "build_package:make_install_package: stop... "
      sleep(5)
    end

  end
  
  def check_dependencies(source_package)
    puts "Checking Dependency for: #{source_package['info']['name']} "
    puts "Recipe Dependencies: #{source_package['dependencies'].inspect}" unless source_package['dependencies'].nil? 
    source_package['dependencies']['build'].each do |dependency|
      package = load_package(dependency)
      puts "Dependency->Build: #{package['info']['name']} "
      build_package(package, "build")
      puts "Dependency->Build->END: #{package['info']['name']}"
    end unless source_package['dependencies'].nil? || source_package['dependencies']['build'].nil?
    
    source_package['dependencies']['source_only'].each do |dependency|
      package = load_package(dependency)
      puts "Dependency->Build: #{package['info']['name']} "
      build_package(package, "source_only")
      puts "Dependency->Build->END: #{package['info']['name']}"
    end unless source_package['dependencies'].nil? || source_package['dependencies']['source_only'].nil?
  end

  def fetch_files
    package_list.each do | file_name |
      package = load_package(file_name)
      fetch_file(package)
    end
  end

  def pack_unpack_folder(package)
    if package['info']['unpack_folder'].nil?
      unpack_folder = package['info']['pack_folder']
    else
      unpack_folder = package['info']['unpack_folder']
    end
  end

  def build_target(package)
    if package['build']['target'].nil? || package['build']['target'] == 'yes'
      "--target=#{config.linux_basic_settings['variables']['linux_target']}"
    elsif package['build']['target'] == 'no'
      ""
    end
  end
  
  def configure_package(package)
    
    unpack_folder = pack_unpack_folder(package)
    unpack_path = "#{WORK}/#{unpack_folder}"
    compile_folder = package['info']['compile_folder']
    compile_path = "#{WORK}/#{compile_folder}"
    
    unless compile_folder.nil?
      FileUtils.cd(compile_path)
      compile_path = "../#{unpack_folder}"
      puts "== vai rodar em compile_path com unpack_folder"
    else
      FileUtils.cd(unpack_path)
      puts "== vai rodar em unpack_path com ."
      compile_path = "."
    end
    
    options = package['build']['options']
    target = build_target(package) 
    prefix = "--prefix=/tools"
    #eprefix = "--exec-prefix=/usr"
    configure_line = "#{compile_path}/configure #{prefix} #{target} #{options}"
    puts "== Linha do configure #{configure_line}"
    configure = system(configure_line)

    FileUtils.cd(KOSH_LINUX_ROOT)
    puts "------------------------======================"
    puts configure
    return configure
  end

  def make_package(package)
    unpack_folder = "#{WORK}/#{pack_unpack_folder(package)}"
    compile_folder = "#{WORK}/#{package['info']['compile_folder']}"

    unless compile_folder
      FileUtils.cd(compile_folder)
      puts "== make_package: running on compile_folder: #{compile_folder}"
    else
      FileUtils.cd(unpack_folder)
      puts "== make_package: running on unpack_folder: #{unpack_folder}"
    end
    
    make = system("make")
    FileUtils.cd(KOSH_LINUX_ROOT)
    return make
  end

  def make_install_package(package)
    unpack_folder = "#{WORK}/#{pack_unpack_folder(package)}"
    compile_folder = "#{WORK}/#{package['info']['compile_folder']}"

    unless compile_folder
      FileUtils.cd(compile_folder)
      puts "== make_install_package: running on compile_folder: #{compile_folder}"
    else
      FileUtils.cd(unpack_folder)
      puts "== make_install_package: running on unpack_folder: #{unpack_folder}"
    end

    make_install = system("make install")
    FileUtils.cd(KOSH_LINUX_ROOT)
    return make_install
  end

  def unpack_file(package)
    file_name = package['info']['filename']
    archive_path = "#{SOURCES}/#{file_name}"
    pack_folder = "#{WORK}/#{package['info']['pack_folder']}"
    unpack_folder = "#{WORK}/#{pack_unpack_folder(package)}"
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

