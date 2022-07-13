# zsh

## Debugging zsh startup time

1. Inject profiling code at the top of zshrc:

```
zmodload zsh/zprof
```

2. Measure startup time by doing:

```
time zsh -i -c ext
```

3. Profit?
