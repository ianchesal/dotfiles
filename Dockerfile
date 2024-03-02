# You can use this to build a docker'ized version of my environment.
# This gives you a portable devenv or a nice way to try out my
# dotfiles.
FROM debian:bookworm

RUN apt-get update && \
  apt-get install -y locales && \
  rm -rf /var/lib/apt/lists/* && \
  localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf

# Install the base layer of tools we need in Debian
RUN apt-get update && \
  apt-get install -y build-essential procps curl file git && \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
  eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv) && \
  brew doctor && \
  brew install gcc
