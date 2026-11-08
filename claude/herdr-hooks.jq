# Migrate a live ~/.claude/settings.json to the herdr-aware hooks without
# touching anything else in it. Run by `just claude::herdr-hooks`.
#
# ~/.claude/settings.json is create_-only, so a machine seeded before the hooks
# changed never gets them from chezmoi, and machines drift apart. This edits
# only the hooks block, surgically, so machine-only hooks survive:
#   1. drops every hook command that calls workmux, then any matcher group or
#      event left empty
#   2. adds the herdr-context.sh and herdr-status.sh hooks from
#      home/dot_claude/create_private_settings.json, unless a command already
#      names them
# herdr's own herdr-agent-state.sh entry is left alone. Idempotent.

.hooks //= {}
| .hooks |= with_entries(
    .value |= map(.hooks |= map(select(.command | test("workmux") | not)) | select(.hooks | length > 0))
  )
| .hooks |= with_entries(select(.value | length > 0))
# 2. add the two herdr hooks unless a command already names them
| def add($event; $matcher; $cmd):
    if [.hooks[$event][]?.hooks[]?.command] | any(contains($cmd | split(" ") | last))
    then .
    else .hooks[$event] += [{matcher: $matcher, hooks: [{type: "command", command: $cmd, timeout: 10}]}]
    end;
  add("SessionStart"; "startup|resume|clear|compact"; "bash ~/.claude/hooks/herdr-context.sh")
| add("PostToolUse"; "Write|Edit|MultiEdit"; "bash ~/.claude/hooks/herdr-status.sh")
