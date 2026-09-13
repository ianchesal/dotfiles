#!/usr/bin/env bash
# Sourced helper: prints the installed claude-code deb version, or nothing when
# the deb is not installed (including on every non-Linux box).
#
# Used by just/claude.just to tell an apt-managed claude from a curl-installed
# one -- see the comment at the top of that file for why the difference matters.

apt_claude_version() {
  [ "$(uname -s)" = Linux ] || return 0
  command -v dpkg-query >/dev/null || return 0

  local out status version
  out=$(dpkg-query -W -f='${Status}|${Version}' claude-code 2>/dev/null) || return 0
  status=${out%%|*}
  version=${out#*|}
  case $status in
    *"install ok installed"*) printf '%s\n' "$version" ;;
    *) return 0 ;;
  esac
}
