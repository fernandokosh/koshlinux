#!/bin/bash

export LC_ALL=C
export WORK="./"
export LFS=$WORK
export TOOLS=$WORK/tools
export LC_ALL=POSIX
export ARCH=x86_64
export PLATFORM=i686-pc-linux-gnu
export LINUX_TARGET=x86_64-pc-linux-gnu
export LFS_TGT=$LINUX_TARGET
export PATH=/tools/bin:/bin:/usr/bin

echo "===== WORK: $WORK"

SPECS=`dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/specs
$LFS_TGT-gcc -dumpspecs | sed \
  -e 's@/lib\(64\)\?/ld@/tools&@g' \
  -e "/^\*cpp:$/{n;s,$, -isystem /tools/include,}" > $SPECS 
echo "New specs file is: $SPECS"
unset SPECS
