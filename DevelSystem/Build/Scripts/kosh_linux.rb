require 'Scripts/linux_config'
require 'Scripts/linux_build'
require 'Scripts/linux_packager'


class KoshLinux

  def packager
    @@packager = Packager.new
  end

  def config
    @@config = Config.new
  end

end

