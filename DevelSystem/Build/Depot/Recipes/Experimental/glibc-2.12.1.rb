class Glibc < Package

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

class BuildGlibc < Glibc

  def initialize
    @name = 'Build Glibc'
    @patches_options = "-Np1"
    @patches = {
      :glibc_2_12_1_gcc_fix_1 => {
        :name => 'Glibc GCC Build Fix Patch',
        :size => '2.5',
        :download => 'http://www.linuxfromscratch.org/patches/lfs/6.7/glibc-2.12.1-gcc_fix-1.patch',
        :md5 => 'd1f28cb98acb9417fe52596908bbb9fd',
        :options => "-Np1",
      },
    :glibc_2_12_1_makefile_fix_1 => {
      :name => 'Glibc Makefile Fix Patch',
      :size => '1',
      :download => 'http://www.linuxfromscratch.org/patches/lfs/6.7/glibc-2.12.1-makefile_fix-1.patch',
      :md5 => '0ef634ac78e582f45d0e7643bfda7505',
      }
    }
  end

end
