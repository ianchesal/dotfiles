# dotfiles/python

Python toolchain configuration. Installs a pinned Python via
[pyenv](https://github.com/pyenv/pyenv), activates it globally, and symlinks the
lint config.

## Requirements

- `pyenv` must already be installed (the install task aborts if missing —
  bootstrapping pyenv is left as a manual, OS-specific step)

## Layout

```
python.rake   Install/activate/update/clean rake tasks
pylintrc      Symlinked to ~/.pylintrc
```

Pinned Python version: `3.11.4`.

## Tasks

- `rake python` — install Python and dependencies (install, activate, symlink rc, update)
- `rake python:install` — install the pinned Python with pyenv
- `rake python:update` — update Python packages (`pip`, `pipenv`, `pylint`)
