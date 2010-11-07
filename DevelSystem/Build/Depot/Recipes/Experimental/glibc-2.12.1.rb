class BuildGlibc

  attr_reader :name, :version, :filename, :size, :homepage

  def initialize
    @name = 'Glibc'
    @version = '2.12.1'
    @filename = 'glibc-2.12.1.tar.bz2'
    @size = '15,300'
    @homepage = 'http://www.gnu.org/software/libc/'
    @description = "The Glibc package contains the main C library. This library provides 
  the basic routines for allocating memory, searching directories, opening and closing 
  files, reading and writing files, string handling, pattern matching, arithmetic, 
  and so on."
    @download = 'http://ftp.gnu.org/gnu/glibc/glibc-2.12.1.tar.bz2'
    @md5 = 'be0ea9e587f08c87604fe10a91f72afd'
    @packer = 'tar.bz2'
    @pack_folder = 'glibc-2.12.1'
    @unpack_folder = ''
    @compile_folder = 'glibc-build'
  end

end