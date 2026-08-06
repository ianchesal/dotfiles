# dotfiles

<!-- hy-mt2-i18n:start -->
[English](./README.md) | **中文** | [日本語](./README_ja.md) | [Español](./README_es.md)
<!-- hy-mt2-i18n:end -->


[![CI](https://github.com/ianchesal/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/ianchesal/dotfiles/actions/workflows/ci.yml)

[![forthebadge](https://forthebadge.com/images/badges/0-percent-optimized.svg)](https://forthebadge.com)

我的 dotfiles 文件。你还期望有什么别的东西呢？

## 使用方法

    mkdir -p ~/src
    pushd ~/src
    git clone git@github.com:ianchesal/dotfiles.git
    cd dotfiles
    rake all

你可以利用附带的 `Rakefile` 将这些组件相互关联起来。详情请参阅：

    rake -T

该命令可以显示可用于连接各组件的目标。并非所有功能都能通过 `Rakefile` 实现自动安装。
