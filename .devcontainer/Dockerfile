FROM debian:latest

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  apt-utils \
  curl \
  git \
  gnupg \
  procps \
  python3 \
  python3-pip \
  sudo \
  wget \
  # Install Neovim from official release
  && mkdir -p /tmp/neovim \
  && cd /tmp/neovim \
  && wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz \
  && tar xzf nvim-linux64.tar.gz \
  && cp -r nvim-linux64/* /usr \
  # Clean up
  && rm -rf /tmp/neovim \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

# Create a non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
  && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

# Set the default user
USER $USERNAME

