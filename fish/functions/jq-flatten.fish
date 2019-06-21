function jq-flatten
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
    ' $argv
end
