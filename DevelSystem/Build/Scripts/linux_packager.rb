require 'net/http'
require 'md5'
require 'fileutils'
require 'open-uri'
require File.join(KoshLinux::KOSH_LINUX_ROOT,'Vendor','ruby-progressbar','lib','progressbar')

class Packager
  attr_accessor :config, :options
  private_class_method :new
  @@packager = nil

  def Packager.create
    @@packager = new unless @@packager
    @@packager
  end

  def initialize
    @config = Config.create
    @packages = @config.profile_settings['packages']
  end

  def build_all
    @packages.each do | file_name |
      @package = load_package(file_name)
      build_package(@package)
    end
  end

  def build_package(package, operation="run")
    if package_status(package) && @options[:force_rebuild] == false
      puts "Package #{package['name']} already built"
      return true
    end

    hook_package('fetch', 'pre', package)
    unless package['fetch'].nil?
      fetch_file(package) unless package['fetch']['do'] == false
    else
      fetch_file(package)
    end
    hook_package('fetch', 'post', package)

    hook_package('unpack', 'pre', package)
    unless package['unpack'].nil?
      unpack_file(package) unless package['unpack']['do'] == false
    else
      unpack_file(package)
    end
    hook_package('unpack', 'post', package)

    hook_package('patch', 'pre', package)
    patch_package(package)
    hook_package('patch', 'post', package)

    unless package['dependencies'] == false
      check_dependencies(package)
    end

    if operation == "build" || operation == "run"
      hook_package('configure', 'pre', package)
      unless package['configure'].nil?
        puts "build_package: configure start ::.#{package['info']['name']}.:: "
        configure_package(package) unless package['configure']['do'] == false
        puts "build_package: configure end ::.#{package['info']['name']}.:: "
      else
        configure_package(package)
      end
      hook_package('configure', 'post', package)

      hook_package('make', 'pre', package)
      unless package['make'].nil?
        puts "build_package:make_package: start... ::.#{package['info']['name']}.:: "
        make_package(package) unless package['make']['do'] == false
        puts "build_package:make_package: end... ::.#{package['info']['name']}.:: "
      else
        make_package(package)
      end
      hook_package('make', 'post', package)
    end

    unless operation=="source_only"
      hook_package('make_install', 'pre', package)
      unless package['make_install'].nil?
        puts "build_package:make_install_package: start... ::.#{package['info']['name']}.::"
        make_install_package(package) unless package['make_install']['do'] == false
        puts "build_package:make_install_package: end... ::.#{package['info']['name']}.::"
      else
        make_install_package(package)
      end
      hook_package('make_install', 'post', package)
    end
    package_status(package, 'ok', 'Package built!')
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

  def pack_unpack_folder(package)
    if package['info']['unpack_folder'].nil?
      unpack_folder = package['info']['pack_folder']
    else
      unpack_folder = package['info']['unpack_folder']
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
    unless package['configure'].nil?
      options = "#{package['configure']['options']}"
      variables = "#{package['configure']['variables']}"
    end
    
    prefix = "--prefix=$TOOLS"
    log_file = "#{KoshLinux::LOGS}/configure_#{package['name']}"
    configure_line = "#{variables} #{compile_path}/configure #{prefix} #{options} 2>#{log_file}.err 1>#{log_file}.out"
    puts "== Configure line: #{configure_line}"
    puts "Output command configure => #{log_file}"
    configure = environment_box(configure_line)
    abort("Exiting on configure: #{package['name']}") if configure.nil?
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
    unless package['make'].nil?
      options = "#{package['make']['options']}"
      variables = "#{package['make']['variables']}"
    end
    log_file = "#{KoshLinux::WORK}/logs/make_#{package['name']}"
    make_line = "#{variables} make #{options} 2>#{log_file}.err 1>#{log_file}.out"
    puts "== Line of make: #{make_line}"
    puts "Output command make => #{log_file}"
    make = environment_box(make_line)
    abort("Exiting on make: #{package['name']}") if make.nil?
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
    unless package['make_install'].nil?
      options = "#{package['make_install']['options']}"
      variables = "#{package['make_install']['variables']}"
    end
    log_file = "#{KoshLinux::LOGS}/make_install_#{package['name']}"
    make_install_line = "#{variables} make #{options} install 2>#{log_file}.err 1>#{log_file}.out "
    puts "== Line of make_install: #{make_install_line}"
    puts "Output command make install => #{log_file}"
    make_install = environment_box(make_install_line)
    abort("Exiting on make_install: #{package['name']}") if make_install.nil?
    FileUtils.cd(KoshLinux::KOSH_LINUX_ROOT)
    return make_install
  end

  def unpack_file(package)
    file_name = package['info']['filename']
    archive_path = "#{KoshLinux::SOURCES}/#{file_name}"
    pack_folder = package['info']['pack_folder']
    pack_path = "#{KoshLinux::WORK}/#{pack_folder}"
    unpack_folder = pack_unpack_folder(package)
    unpack_path = "#{KoshLinux::WORK}/#{unpack_folder}"
    compile_folder = "#{KoshLinux::WORK}/#{package['info']['compile_folder']}"
    packer = package['info']['packer']
    puts "Unpack path: #{unpack_path}"
    if options[:keep_work] && File.exists?(unpack_path)
      puts "Using previously unpacked: #{unpack_path}"
      check_compile_path
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
       abort("Error: Unreconized packer type: #{packer}")
    end
    check_compile_path
    unless pack_folder == unpack_folder
      puts "Renaming file: #{pack_path} => #{unpack_path}"
      FileUtils.cd(KoshLinux::WORK)
      FileUtils.mv(pack_folder, unpack_folder)
      FileUtils.cd(KoshLinux::KOSH_LINUX_ROOT)
    end
  end

  def unpack_tar_bz2(file_path)
    FileUtils.cd(KoshLinux::WORK)
    system("#{KoshLinux::KOSH_LINUX_ROOT}/Vendor/bar/bar #{file_path} | tar --recursive-unlink -xjUpf -")
    FileUtils.cd(KoshLinux::KOSH_LINUX_ROOT)
  end

  def unpack_tar_gz(file_path)
    FileUtils.cd(KoshLinux::WORK)
    system("#{KoshLinux::KOSH_LINUX_ROOT}/Vendor/bar/bar #{file_path} | tar --recursive-unlink -xzUpf -")
    FileUtils.cd(KoshLinux::KOSH_LINUX_ROOT)
  end

  def check_compile_path
    compile_folder = @package['info']['compile_folder']
    compile_path   = "#{KoshLinux::WORK}/#{compile_folder}"
    unless compile_folder.nil?
      puts "Creating compile folder: #{compile_folder} on: #{compile_path}"
      FileUtils.mkdir_p(compile_path)
    end
  end

  def load_package(file_name)
    file_path = "#{KoshLinux::PACKAGES}/#{file_name}.yml"
    puts "Loading Recipe (#{file_name}) "
    package = YAML::load_file(file_path)
    package["name"] = file_name
    return package
  end

  def fetch_file(package)
    file_name = package['info']['filename']
    file_path = "#{KoshLinux::SOURCES}/#{file_name}"
    download_url = package['info']['download']

    fetch_file_download(download_url, package['info']['md5'], file_name)
  end

  def check_for_checksum(file_path, checksum)
    Digest::MD5.hexdigest(File.read(file_path)) == checksum
  end

  def fetch_file_download(url_for_download, checksum, file_name=nil)
    uri = URI.parse(url_for_download)
    filename = file_name.nil? ? File.basename(uri.path) : file_name
    filepath = "#{KoshLinux::SOURCES}/#{filename}"
    only_url = File.dirname(url_for_download)
    result = nil

    unless File.exist?(filepath) && check_for_checksum(filepath, checksum)
      puts "Connecting on #{uri.host}, for download the file #{filename}"
      begin
        pbar = nil
        uri.open(:content_length_proc => lambda {|t|
                   if t && 0 < t;
                     puts "Downloading file #{filename} from #{only_url} "
                     pbar = ProgressBar.new(filename, t)
                     pbar.file_transfer_mode
                   end
                 },
                 :progress_proc => lambda {|s|
                   pbar.set s if pbar
                 }) do |file|
          open(filepath, 'wb') do |archive|
            archive.write(file.read)
            archive.close
            result = filepath
          end
        end
      rescue Errno::ETIMEDOUT
        puts "Timeout error, trying again in few seconds..."
        sleep 3
        result = fetch_file_download(url_for_download, checksum, file_name)
      rescue SocketError
        puts "I got error, is your network up? trying again in few seconds..."
        sleep 5
        result = fetch_file_download(url_for_download, checksum, file_name)
      else
        puts "Download complete."
      end
    else
      puts "Skip download, using previously downloaded archive #{file_name}..."
      result = filepath
    end
    return result
  end

  def hook_package(action, hook, package)
    return if package[action].nil?
    current_hook = package[action][hook]
    unless current_hook.nil? || current_hook.empty?
      puts "_== Running hook(#{package['name']}:#{action}.#{hook}): #{current_hook}"
      compile_path = package['info']['compile_folder']
      compile_path = pack_unpack_folder(package) if compile_path.nil?
      FileUtils.cd("#{KoshLinux::WORK}/#{compile_path}")
      log_file = "$LOGS/#{action}-#{hook}_#{package['name']}"
      output_log = " 2>#{log_file}.err 1>#{log_file}.out" 
      result = environment_box(current_hook + output_log)
      puts "_== End hook(#{action}.#{hook}) ==__"
      abort("Exiting hook(#{package['name']}:#{action}.#{hook})") if result.nil?
    end
  end

  def patch_package(package)
    info = package['info']
    patches = info['patches']
    return if patches.nil?
    options = info['patches_options']
    puts "Checking for #{patches.count} patch(es)"
    patches.each do |patch|
      patch_info = patch[1]
      filepath = fetch_file_download(patch_info['download'],patch_info['md5'])
      if filepath
        work_folder = "#{KoshLinux::WORK}/#{pack_unpack_folder(package)}"
        FileUtils.cd(work_folder)
        unless File.exist?(patch[0])
          options = patch_info['options'] unless patch_info['options'].nil?
          puts "__== Appling patch: #{patch_info['name']} ==__"
          log_file = "$LOGS/patch_#{package['name']}"
          command_for_patch = "patch #{options} -i #{filepath} 2>#{log_file}.err 1>#{log_file}.out && echo 'patched' >#{patch[0]}"
          result = environment_box(command_for_patch)
          abort("Error appling patch (#{package['name']}:#{patch_info['name']})") if result.nil?
        else
          puts "No needed patch: #{patch_info['name']}"
        end
      else
        abort("Erro with downloading: #{patch_info['name']}")
      end
    end
  end

  def environment_box(which_command)
    ENV['HOME']  = KoshLinux::WORK
#    ENV['TERM']  = 'ansi'
    ENV['BUILD'] = KoshLinux::KOSH_LINUX_ROOT
    ENV['WORK']  = KoshLinux::WORK
    ENV['TOOLS'] = KoshLinux::TOOLS
    ENV['LOGS']  = KoshLinux::LOGS
    ENV['PATH']  = "#{KoshLinux::TOOLS}/bin:/bin:/usr/bin"

    environment = "env -i HOME='#{ENV['HOME']}' TERM='#{ENV['TERM']}' BUILD='#{ENV['BUILD']}' WORK='#{ENV['WORK']}' TOOLS='#{ENV['TOOLS']}' LOGS='#{ENV['LOGS']}' PATH='#{ENV['PATH']}'"

    file_path = "#{KoshLinux::PROFILES}/LinuxBasic.yml"
    variables = YAML::load( File.open( file_path ))['variables']
    variables.inject("") do |vars, variable|
      ENV[variable[0].upcase] = variable[1]
      environment += " #{variable[0].upcase}='#{variable[1]}'"
    end

    extra_options = ""
    extra_options += "set -x; " if @options[:debug]
    extra_options += "set +h; "
    extra_options += "umask 022; "
    command_line = "#{extra_options} #{which_command}"
    puts "Command Line: #{command_line}" if @options[:debug]
    %x[exec #{environment} bash -c "#{command_line}" ]
    command_status = $?.exitstatus
    puts "Command exitstatus(#{command_status})"
    if command_status > 0
      puts "Command line was: #{command_line}"
      result = nil
    else
      result = true
    end
    result
  end

  def package_status(package, status=nil, message=nil)
    filename=[KoshLinux::WORK,'.status', package['name'] , 'ok'].join('/')
    dirname=File.dirname(filename)
    statusdir=File.dirname(dirname)
    FileUtils.mkdir(statusdir) unless File.exist?(statusdir)
    FileUtils.mkdir(dirname) unless File.exist?(dirname)

    if status.nil?
      return true if File.exist?(filename)
      return false
    end
    case status
    when 'ok' then
      ok_file = File.open(filename,'w').write(message)
      return true
    when 'clear' then
      FileUtils.rm_f(filename)
      return true
    end
  end

  def spinner(locker)
    chars = %w{ | / - \\ }
    t = Thread.new{
      while File.exist?(locker)
        output = "Please wait (#{chars[0]})"
        $stderr.print output
        sleep 0.2
        output.size.times do
          $stderr.print "\b"
        end
        chars.push chars.shift
      end
    }
  end
end
