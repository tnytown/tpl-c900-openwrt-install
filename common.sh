u() {
  c go run "$UTIL" "$@"
}

c() {
  echo "[-]" "$@"
  eval $@
}

export UTIL=$(find `dirname $(pwd)` -name decrypt.go)
source .encryption_params
