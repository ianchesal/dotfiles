#!/usr/bin/env python3
"""Generate ~/.config/zsh/completions/_claude from `claude --help`.

Writes straight to the deployed path rather than a chezmoi source file. The spec
is parsed from the locally installed `claude --help`, which makes it per-machine
state: while it was tracked, every version bump dirtied the repo and a
`chezmoi apply` on a second machine clobbered that machine's correct spec with
the first one's. Same category as the `_kubectl` spec zshrc.d/kubernetes.zsh
caches at runtime. The destination is already on fpath
(home/dot_config/zsh/dot_zshrc) and its dir carries no `exact_` prefix, so an
unmanaged file there survives every apply -- but nothing else regenerates it, so
this script is the only thing keeping it current.

`--if-missing` exits quietly when the spec is already there. That is how
`just claude::update` seeds a fresh machine without reparsing on every run, and
it keeps the destination path known in exactly one place.

Run directly or via: just claude::gen-completions
"""

import os
import pathlib
import re
import subprocess
import sys


def capture(*cmd):
    """Run cmd and return (stdout, stderr), or (None, None) if it is not installed."""
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    except FileNotFoundError:
        return None, None
    return result.stdout, result.stderr


def parse_help(help_text):
    """Split `claude --help` into its option and command entries."""
    options, commands = [], []
    section = None

    for raw in help_text.splitlines():
        line = raw.rstrip("\n")
        stripped = line.strip()

        if stripped == "Options:":
            section = "options"
            continue
        if stripped == "Commands:":
            section = "commands"
            continue
        if stripped == "Arguments:":
            section = "arguments"
            continue
        if not stripped:
            continue

        if section == "options":
            match = re.match(r"^\s{2}(-\S.*?)\s{2,}(.+)$", line)
            if not match:
                continue
            flags_and_arg = match.group(1).strip()
            description = match.group(2).strip()

            arg_spec = ""
            flags_str = flags_and_arg
            arg_match = re.match(r"^(.*?)\s+(\[.+?\]|<.+?>)\s*$", flags_and_arg)
            if arg_match:
                flags_str = arg_match.group(1)
                arg_spec = arg_match.group(2)

            flags = [f.strip() for f in re.split(r",\s*", flags_str) if f.strip()]

            choices = []
            choice_match = re.search(r"\(choices:\s+(.+?)\)\s*$", description)
            if choice_match:
                raw_choices = choice_match.group(1)
                choices = re.findall(r'"([^"]+)"', raw_choices)
                if not choices:
                    choices = [c.strip() for c in re.split(r",\s*", raw_choices)]

            options.append(
                {"flags": flags, "arg": arg_spec, "description": description, "choices": choices}
            )

        elif section == "commands":
            match = re.match(r"^\s{2}(\S+)\s{2,}(.+)$", line)
            if not match:
                continue
            commands.append(
                {"name": match.group(1).split("|")[0], "description": match.group(2).strip()}
            )

    return options, commands


def first_sentence(text):
    """Truncate to the first sentence, to keep descriptions brief."""
    parts = re.split(r"(?<=\.)\s+", text)
    return parts[0] if parts else ""


def short_desc(text):
    return (
        first_sentence(text)
        .replace("[", "\\[")  # escape zsh bracket metacharacters
        .replace("]", "\\]")
        .replace("'", "'\\''")  # escape single quotes: ' -> '\''
        .strip()
    )


def short_subcmd_desc(text):
    return first_sentence(text).replace("'", "'\\''").replace(":", "\\:").strip()


def option_spec_lines(options):
    """Render each option as a zsh _arguments spec line."""
    lines = []
    for opt in options:
        flags = opt["flags"]
        arg = opt["arg"]
        desc = short_desc(opt["description"])
        choices = opt["choices"]

        arg_name = arg.translate(str.maketrans("", "", "<>[]")).strip().split(".")[0].replace(" ", "-")
        optional = arg.startswith("[")

        if choices:
            arg_completion = ":%s:(%s)" % (arg_name, " ".join(choices))
        elif arg:
            arg_completion = ":%s:" % arg_name
        else:
            arg_completion = ""
        if optional and arg_completion:
            arg_completion = ":" + arg_completion

        shorts = [f for f in flags if re.match(r"^-[^-]", f)]
        if len(flags) == 2 and shorts:
            short = shorts[0]
            long = next((f for f in flags if f.startswith("--")), None)
            lines.append(
                "    '(%s %s)'{%s,%s}'[%s]%s' \\" % (short, long, short, long, desc, arg_completion)
            )
        else:
            for flag in flags:
                lines.append("    '%s[%s]%s' \\" % (flag, desc, arg_completion))
    return lines


def render(version, options, commands):
    spec_lines = "\n".join(option_spec_lines(options))
    subcmd_lines = "\n".join(
        "      '%s:%s'" % (c["name"], short_subcmd_desc(c["description"])) for c in commands
    )
    return f"""#compdef claude
# Generated by script/gen-claude-completions.py from claude {version}
# Do not edit by hand — regenerate with: just claude::gen-completions

_claude() {{
  local context state state_descr line
  typeset -A opt_args

  _arguments -C \\
{spec_lines}
    '1:prompt:' \\
    '*::args:->subcmd' && return 0

  case $state in
    subcmd)
      local -a subcommands
      subcommands=(
{subcmd_lines}
      )
      _describe 'subcommand' subcommands
      ;;
  esac
}}

_claude "$@"
"""


def completion_dest():
    """The live completions dir on fpath -- deliberately not a chezmoi source path."""
    zdotdir = os.environ.get("ZDOTDIR") or str(pathlib.Path.home() / ".config" / "zsh")
    return pathlib.Path(zdotdir).expanduser() / "completions" / "_claude"


def main():
    args = sys.argv[1:]
    if_missing = "--if-missing" in args
    if [a for a in args if a != "--if-missing"]:
        print(f"usage: {pathlib.Path(sys.argv[0]).name} [--if-missing]", file=sys.stderr)
        return 2

    dest = completion_dest()
    if if_missing and dest.exists():
        return 0

    help_out, help_err = capture("claude", "--help")
    if help_out is None:
        print("claude is not installed; nothing to generate", file=sys.stderr)
        return 1
    help_text = help_out + help_err
    version_out, _ = capture("claude", "--version")
    version = version_out.strip()

    options, commands = parse_help(help_text)
    if not options and not commands:
        print("claude --help produced nothing to parse; refusing to write", file=sys.stderr)
        return 1

    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(render(version, options, commands))
    print(f"Wrote {dest} ({version})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
