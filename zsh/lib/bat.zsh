cat() {
  if _has bat; then
    command bat $*
  else
    command cat $*
  fi
}
