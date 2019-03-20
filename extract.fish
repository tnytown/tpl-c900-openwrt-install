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


u -in backup.bin -out backup.zz.tmp dec
u -in backup.zz.tmp -out backup.bin.tmp dmp

run dd if=backup.bin.tmp of=md5sum bs=1 count=16
run dd if=backup.bin.tmp of=backup.tar.tmp bs=1 skip=16

run mkdir -p data
run tar -xf backup.tar.tmp -C data/

run pushd data
run u -in ori-backup-user-config.bin -out config.zz.tmp dec
run u -in config.zz.tmp -out config.xml dmp
run popd

run rm ./**.tmp
