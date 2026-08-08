# dotfiles

<!-- hy-mt2-i18n:start -->
[English](./README.md) | [中文](./README_zh-CN.md) | [日本語](./README_ja.md) | **Español**
<!-- hy-mt2-i18n:end -->


[![CI](https://github.com/ianchesal/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/ianchesal/dotfiles/actions/workflows/ci.yml)

[![forthebadge](https://forthebadge.com/images/badges/0-percent-optimized.svg)](https://forthebadge.com)

Mis dotfiles. ¿Qué más esperabas?

## Uso

    mkdir -p ~/src
    pushd ~/src
    git clone git@github.com:ianchesal/dotfiles.git
    cd dotfiles
    rake all

Puedes vincular algunas de las partes utilizando el `Rakefile` incluido. Consulta:

    rake -T

para conocer los objetivos que puedes ejecutar para vincular las partes. No todo está disponible para su instalación automática a través del `Rakefile`.
