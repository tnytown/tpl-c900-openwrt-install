#!/usr/bin/env bash

set -euf -o pipefail

UTIL=$(find `dirname $(pwd)` -name decrypt.go)
source .encryption_params

u() {
  go run $UTIL $@
}

c() {
  echo "[-]" $@
  eval $@
}

c pushd data
u -in config.xml -out config.zz.tmp cmp
u -in config.zz.tmp -out ori-backup-user-config.bin enc
c rm config.zz.tmp

c chmod u+r ori-backup-certificate.bin
c tar -cf ../backup.tar.tmp --exclude config.xml .
c popd

cat md5sum backup.tar.tmp > backup.tmp
u -in backup.tmp -out backup.zz.tmp cmp
u -in backup.zz.tmp -out backup_final.bin enc

c rm ./**.tmp
