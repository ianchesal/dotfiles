function jq-flatten() {
  jq -r '
  tostream
  | select(length > 1)
  | (
  .[0] | map(
  if type == "number"
  then "[" + tostring + "]"
  else "." + .
  end
  ) | join("")
  ) + " = " + (.[1] | @json)
  ' $*
}

function uptime.as() {
  curl --silent "https://get.uptime.is/api?sla=${1}" | jq .
}
