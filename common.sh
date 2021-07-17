source .encryption_params

export GO111MODULE=off

u() {
  c go run decrypt.go $@
}

c() {
  echo "[-]" "$@"
  eval $@
}
