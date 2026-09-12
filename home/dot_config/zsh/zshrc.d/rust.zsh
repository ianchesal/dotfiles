# Rust toolchain, installed via rustup
# See: https://rustup.rs
# rustup's env script prepends ~/.cargo/bin to PATH and is idempotent, so it is
# safe to source even when a system rustc is already present.
if [[ -r "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi
