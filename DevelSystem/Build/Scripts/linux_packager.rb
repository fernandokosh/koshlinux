require 'net/http'
require 'md5'
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
      hook_package('pre_configure')
      unless package['build']['do_configure'] == false
        puts "build_package: configure start ::.#{package['info']['name']}.:: "
        configure_package(package)
        puts "build_package: configure end ::.#{package['info']['name']}.:: "
        sleep(3)
      end
      hook_package('post_configure')
      
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
      hook_package('pre_make_install')
      unless package['build']['do_make_install'] == false
        puts "build_package:make_install_package: start... ::.#{package['info']['name']}.::"
        sleep(2)
        make_install_package(package)
        puts "build_package:make_install_package: end... ::.#{package['info']['name']}.::"
        sleep(3)
      end
      hook_package('post_make_install')
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
      "--target=$LINUX_TARGET"
    elsif package['build']['target'] == 'no'
      ""
    end
  end

  def configure_package(package)
    unpack_folder = pack_unpack_folder(package)
    unpack_path = "#{KoshLinux::WORK}/#{unpack_folder}"
    compile_folder = package['info']['compile_folder']
    compile_path = "#{KoshLinux::WORK}/#{compile_folder}"

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
    prefix = "--prefix=$TOOLS"
    #eprefix = "--exec-prefix=/usr"
    log_file = "#{KoshLinux::LOGS}/configure_#{package['info']['pack_folder']}.out"
    configure_line = "#{compile_path}/configure #{prefix} #{target} #{options} >#{log_file} 2>&1"
    puts "== Configure line: #{configure_line}"
    puts "Output command configure => #{log_file}"
    sleep(2)
    configure = environment_box(configure_line)
    abort("Exiting on configure: #{package['name']}") unless configure
    FileUtils.cd(KoshLinux::KOSH_LINUX_ROOT)
    return configure
  end

  def make_package(package)
    unpack_folder = pack_unpack_folder(package)
    unpack_path = "#{KoshLinux::WORK}/#{unpack_folder}"
    compile_folder = package['info']['compile_folder']
    compile_path = "#{KoshLinux::WORK}/#{compile_folder}"

    puts "compile_folder: #{compile_path} & unpack_folder: #{unpack_path}"
    unless compile_folder.nil?
      FileUtils.cd(compile_path)
      puts "== make_package: running on compile_folder: #{compile_path}"
    else
      FileUtils.cd(unpack_path)
      puts "== make_package: running on unpack_folder: #{unpack_path}"
    end
    log_file = "#{KoshLinux::WORK}/logs/make_#{package['info']['pack_folder']}.out"
    make_line = "make >#{log_file} 2>&1"
    puts "== Line of make: #{make_line}"
    puts "Output command make => #{log_file}"
    make = environment_box(make_line)
    abort("Exiting on make: #{package['name']}") unless make
    FileUtils.cd(KoshLinux::KOSH_LINUX_ROOT)
    return make
  end

  def make_install_package(package)
    unpack_folder = pack_unpack_folder(package)
    unpack_path = "#{KoshLinux::WORK}/#{unpack_folder}"
    compile_folder = package['info']['compile_folder']
    compile_path = "#{KoshLinux::WORK}/#{compile_folder}"

    unless compile_folder.nil?
      FileUtils.cd(compile_path)
      puts "== make_install_package: running on compile_folder: #{compile_path}"
    else
      FileUtils.cd(unpack_path)
      puts "== make_install_package: running on unpack_folder: #{unpack_path}"
    end
    log_file = "#{KoshLinux::LOGS}/make_install_#{package['info']['pack_folder']}.out"
    make_install_line = "make install >#{log_file} 2>&1 "
    puts "== Line of make_install: #{make_install_line}"
    puts "Output command make install => #{log_file}"
    make_install = environment_box(make_install_line)
    abort("Exiting on make_install: #{package['name']}") unless make_install
    FileUtils.cd(KoshLinux::KOSH_LINUX_ROOT)
    return make_install
  end

  def unpack_file(package)
    file_name = package['info']['filename']
    archive_path = "#{KoshLinux::SOURCES}/#{file_name}"
    pack_folder = "#{KoshLinux::WORK}/#{package['info']['pack_folder']}"
    unpack_folder = "#{KoshLinux::WORK}/#{pack_unpack_folder(package)}"
    compile_folder = "#{KoshLinux::WORK}/#{package['info']['compile_folder']}"
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
      FileUtils.cd(KoshLinux::WORK)
      FileUtils.mv(pack_folder, unpack_folder)
      FileUtils.cd(KoshLinux::KOSH_LINUX_ROOT)
    end
  end

  def unpack_tar_bz2(file_path)
    FileUtils.cd(KoshLinux::WORK)
    system("tar -xjf #{file_path}")
    FileUtils.cd(KoshLinux::KOSH_LINUX_ROOT)
  end

  def unpack_tar_gz(file_path)
    FileUtils.cd(KoshLinux::WORK)
    system("tar -xzf #{file_path}")
    FileUtils.cd(KoshLinux::KOSH_LINUX_ROOT)
  end

  def load_package(file_name)
    package = config.load_package(file_name)
    package['name'] = file_name
    puts "Loading Recipe (#{package['name']}): #{package.inspect}"
    return package
  end

  def fetch_file(package)
    file_name = package['info']['filename']
    file_path = "#{KoshLinux::SOURCES}/#{file_name}"
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
    unless current_hook.nil? || current_hook.empty?
      puts "_== Running hook(#{hook}): #{current_hook}"
      compile_path = @package['info']['compile_folder']
      compile_path = @package['info']['unpack_folder'] if compile_path.nil?
      FileUtils.cd("#{KoshLinux::WORK}/#{compile_path}")
      result = environment_box(current_hook)
      puts "_== End hook(#{hook}) ==__"
      abort("Exiting hook(#{hook})") if result.nil?
    end
  end

  def environment_box(which_command)
    #create a file and call from bash, that it, we need bash. soon we
    #don't nned bash anymore
    variables = YAML::load(File.open("#{KoshLinux::PROFILES}/LinuxBasic.yml"))['variables']
    basic_variables=variables.inject("") do |vars, variable|
      vars+="export #{variable[0].upcase}=#{variable[1]}\n"
    end
    bash_script=<<END_OF_SCRIPT
#!/usr/bin/env -i HOME="#{KoshLinux::WORK}" TERM=$TERM /bin/bash

## Base settings ##
set +h
set +x
umask 022
export BUILD=#{KoshLinux::KOSH_LINUX_ROOT}
export TOOLS=#{KoshLinux::TOOLS}
export WORK=#{KoshLinux::WORK}
export PATH=$TOOLS/bin:/bin:/usr/bin

### Setting from LinuxBasic.xml ###
#{basic_variables}

#### Command to execute ####
echo "Starting at folder: $(pwd)"
sleep 1
#{which_command}
echo "Command leave at folder: $(pwd)"
sleep 1
END_OF_SCRIPT
    File.open("#{KoshLinux::WORK}/environment_box.sh", 'w') {|f| f.write(bash_script) }
    system("/bin/bash #{KoshLinux::WORK}/environment_box.sh")
  end
end
