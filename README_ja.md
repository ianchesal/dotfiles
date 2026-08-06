# dotfiles

<!-- hy-mt2-i18n:start -->
[English](./README.md) | [中文](./README_zh-CN.md) | **日本語** | [Español](./README_es.md)
<!-- hy-mt2-i18n:end -->


[![CI](https://github.com/ianchesal/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/ianchesal/dotfiles/actions/workflows/ci.yml)

[![forthebadge](https://forthebadge.com/images/badges/0-percent-optimized.svg)](https://forthebadge.com)

私のdotfilesです。他に何を期待していたのでしょうか？

## 使用方法

    mkdir -p ~/src
    pushd ~/src
    git clone git@github.com:ianchesal/dotfiles.git
    cd dotfiles
    rake all

同梱されている`Rakefile`を使って、各コンポーネントを結びつけることができます。実行可能なターゲットは以下の通りです：

    rake -T

`Rakefile`を通じて自動的にインストールできるものばかりではありません。
