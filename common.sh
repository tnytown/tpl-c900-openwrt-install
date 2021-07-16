export UTIL=$(find `dirname $(pwd)` -name decrypt.go)
source .encryption_params

u() {
  c go run "$UTIL" "$@"
}

c() {
  echo "[-]" "$@"
  eval $@
}
