# dotfiles/winterm

Settings for [Windows Terminal](https://aka.ms/terminal) (install it from the
Microsoft Store). The settings file is copied (not symlinked) into place,
because symlinks aren't trusted to work reliably across WSL2 and the native
Windows file system.

## Layout

```
settings.json   Windows Terminal settings copied into the app's LocalState
winterm.rake    Install task
```

## Tasks

- `rake winterm` — install the Windows Terminal settings (copies `settings.json`
  into the app's LocalState directory)

## Notes

The copy clobbers any existing edits, so back changes into this repo first.
