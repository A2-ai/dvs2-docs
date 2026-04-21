tree() {
  local dir="$PWD" ignore=
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.treeignore" ]]; then
      ignore="$dir/.treeignore"
      break
    fi
    dir=$(dirname "$dir")
  done
  if [[ -n "$ignore" ]]; then
    command tree --gitfile "$ignore" "$@"
  else
    command tree "$@"
  fi
}
