require 'Scripts/linux_config'
require 'Scripts/linux_build'
require 'Scripts/linux_packager'


class KoshLinux

  def config
    @@config = Config.new
  end

  def packager
    @@packager = Packager.new
    @@packager.config = @@config
    @@packager
  end

end

