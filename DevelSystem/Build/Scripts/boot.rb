
PROFILES = "#{KOSH_LINUX_ROOT}/Profiles"

profile_name = 'KoshLinuxBasic'
profile = "#{PROFILES}/#{profile_name}.yml"
profile_settings = YAML::load( File.open( profile ) )

WORK = "#{KOSH_LINUX_ROOT}/Work"








