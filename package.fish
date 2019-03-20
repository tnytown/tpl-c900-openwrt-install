#!/usr/bin/env fish

set util (realpath decrypt.go)
source .encryption_params

function u
  run go run $util $argv
end

function run
  echo "[-]" $argv
  eval $argv
end

run pushd data
u -in config.xml -out config.zz.tmp cmp
u -in config.zz.tmp -out ori-backup-user-config.bin enc
run rm config.zz.tmp

run chmod u+r ori-backup-certificate.bin
run tar -cf ../backup.tar.tmp --exclude config.xml .
run popd data

run cat md5sum backup.tar.tmp > backup.tmp
u -in backup.tmp -out backup.zz.tmp cmp
u -in backup.zz.tmp -out backup_final.bin enc

run rm ./**.tmp
