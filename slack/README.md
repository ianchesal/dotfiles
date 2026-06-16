# dotfiles/slack

Tweaks for the macOS Slack desktop app: a font-ligature fix and a dark sidebar theme.
There is no rake task — apply these manually.

## Layout

```
fix-fonts.sh    Appends CSS to Slack's ssb-interop.js to disable font ligatures
dracula.md      Dracula sidebar-theme color values and install steps
```

## Notes

- `fix-fonts.sh` patches `/Applications/Slack.app/.../ssb-interop.js` to force a
  sans-serif stack and turn off `liga`/`clig` ligatures. Re-run it after a Slack
  update, since updates overwrite the patched file.
- `dracula.md` holds the Dracula sidebar palette and the Preferences > Sidebar Theme
  steps to apply it. See https://draculatheme.com/slack/
