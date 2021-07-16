#!/usr/bin/env bash

set -euf -o pipefail
source common.sh

u -in backup.bin -out backup.zz.tmp dec
u -in backup.zz.tmp -out backup.bin.tmp dmp

c dd if=backup.bin.tmp of=md5sum bs=1 count=16
c dd if=backup.bin.tmp of=backup.tar.tmp bs=1 skip=16

c mkdir -p data
c tar -xf backup.tar.tmp -C data/

c pushd data
u -in ori-backup-user-config.bin -out config.zz.tmp dec
u -in config.zz.tmp -out config.xml dmp
c popd

c rm ./**.tmp
