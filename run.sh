#!/bin/sh

image=boot.img

[ -f "build/$image" ] &&
  qemu-system-i386 -monitor stdio -fda "build/$image"
