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
      @package = load_package(file_name)
      build_package(@package)
    end      
  end
  
  def build_package(package, operation="run")
  
    unless package['build']['do_fetch'] == false
      fetch_file(package)
    end
    
    unless package['build']['do_unpack'] == false
      unpack_file(package)
    end
    
    unless package['build']['do_dependency'] == false
      check_dependencies(package)
    end

    if operation == "build" || operation == "run"

      unless package['build']['do_configure'] == false
        puts "build_package: configure start ::.#{package['info']['name']}.:: "
        configure_package(package)
        puts "build_package: configure end ::.#{package['info']['name']}.:: "
        sleep(3)
      end
      
      hook_package('pre_make')
      unless package['build']['do_make'] == false
        puts "build_package:make_package: start... ::.#{package['info']['name']}.:: "
        sleep(2)
        make_package(package)
        puts "build_package:make_package: end... ::.#{package['info']['name']}.:: "
        sleep(3)
      end
      hook_package('post_make')
    end
    
    unless operation=="source_only"
      unless package['build']['do_make_install'] == false
        puts "build_package:make_install_package: start... ::.#{package['info']['name']}.::"
        sleep(2)
        make_install_package(package)
        puts "build_package:make_install_package: end... ::.#{package['info']['name']}.::"
        sleep(3)
      end
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
      puts "== configure_package: compile_path:{#{compile_path}} with unpack_folder:{#{unpack_path}}"
    else
      FileUtils.cd(unpack_path)
      puts "== configure_package: running on unpack_path:{#{unpack_path}} with ."
      compile_path = "."
    end
    
    options = package['build']['options']
    target = build_target(package) 
    prefix = "--prefix=/tools"
    #eprefix = "--exec-prefix=/usr"
    log_file = "#{WORK}/logs/configure_#{package['info']['pack_folder']}.out"
    configure_line = "#{compile_path}/configure #{prefix} #{target} #{options} >#{log_file} 2>&1"
    puts "== Configure line: #{configure_line}"
    puts "Output command configure => #{log_file}"
    sleep(2)
    configure = system(configure_line)
    exit() unless configure
    FileUtils.cd(KOSH_LINUX_ROOT)
    puts "------------------------======================"
    return configure
  end

  def make_package(package)
    unpack_folder = pack_unpack_folder(package)
    unpack_path = "#{WORK}/#{unpack_folder}"
    compile_folder = package['info']['compile_folder']
    compile_path = "#{WORK}/#{compile_folder}"

    puts "compile_folder: #{compile_path} & unpack_folder: #{unpack_path}"
    unless compile_folder.nil?
      FileUtils.cd(compile_path)
      puts "== make_package: running on compile_folder: #{compile_path}"
    else
      FileUtils.cd(unpack_path)
      puts "== make_package: running on unpack_folder: #{unpack_path}"
    end
    log_file = "#{WORK}/logs/make_#{package['info']['pack_folder']}.out"
    make_flags = "#{config.linux_basic_settings['variables']['makeflags']} "
    make_line = "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/tools/lib make #{make_flags} >#{log_file} 2>&1"
    puts "== Line of make: #{make_line}"
    puts "Output command make => #{log_file}"
    make = system(make_line)
    exit() unless make
    FileUtils.cd(KOSH_LINUX_ROOT)
    return make
  end

  def make_install_package(package)
    unpack_folder = pack_unpack_folder(package)
    unpack_path = "#{WORK}/#{unpack_folder}"
    compile_folder = package['info']['compile_folder']
    compile_path = "#{WORK}/#{compile_folder}"

    unless compile_folder.nil?
      FileUtils.cd(compile_path)
      puts "== make_install_package: running on compile_folder: #{compile_path}"
    else
      FileUtils.cd(unpack_path)
      puts "== make_install_package: running on unpack_folder: #{unpack_path}"
    end
    log_file = "#{WORK}/logs/make_install_#{package['info']['pack_folder']}.out"
    make_install_line = "make install >#{log_file} 2>&1 "
    puts "== Line of make_install: #{make_install_line}"
    puts "Output command make install => #{log_file}"
    make_install = system(make_install_line)
    exit() unless make_install
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
  
  def hook_package(hook)
     current_hook = @package['build'][hook]
     puts "Running hook: #{current_hook}"
     system(current_hook) unless current_hook.nil?
     puts "End hook: #{current_hook}"
  end
  
  
end

