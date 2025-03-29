# zsh

So I was growing pretty tired of how slow oh-my-zsh was for me loading new tabs in
Kitty. This is an complete re-do of my zsh configuration use zdotdir and antidote
as the plugin manager.

Mostly this clones zdotdir and how it works. It was a fast way to get bootstrapped
with antidote and not have to be hobbled too much during the learning curve.

And then I customized on top of that.

So, liberally borrowed, you could say.

See:

* zinit: https://github.com/zdharma-continuum/zinit
* zdotdir: https://github.com/getantidote/zdotdir

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
