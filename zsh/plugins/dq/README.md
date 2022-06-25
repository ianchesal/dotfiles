# Dash Query (dq) plugin

This plugin adds command line functionality for [Dash](https://kapeli.com/dash),
an API Documentation Browser for macOS. This plugin requires Dash to be installed
to work.

To use it, add `dq` to the plugins array in your zshrc file:

```zsh
plugins=(... dq)
```

## Usage

- Open and switch to the dash application.
```
dq
```

- Query for something in dash app: `dq query`
```
dq golang
```

- You can optionally provide a keyword: `dq [keyword:]query`
```
dq python:tuple
```
