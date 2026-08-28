# frozen_string_literal: true

desc 'Install the Rust toolchain via rustup'
task rust: ['rust:all']

CARGO_BIN_DIR = home('.cargo', 'bin').freeze

# Environment that keeps a rustup update from stalling an unattended `rake update`.
# Long text like a toolchain's release notes gets handed to $PAGER, which is `less` in an
# interactive shell and then sits on the alternate screen waiting for a keypress. Point
# PAGER at cat so that text just scrolls past, and belt-and-braces a pager that ignores
# PAGER by appending -F (quit if it fits one screen) and -X (leave the alternate screen
# alone) to whatever LESS the caller had -- later less options win. Callers also close
# stdin so nothing else can block on input.
RUST_NON_PAGING_ENV = {
  'PAGER' => 'cat',
  'MANPAGER' => 'cat',
  'GIT_PAGER' => 'cat',
  'LESS' => "#{ENV.fetch('LESS', '')} -F -X".strip
}.freeze

# Returns the path to rustup, or nil when it isn't installed.
#
# rustup lives in ~/.cargo/bin, which zshrc.d/rust.zsh puts on PATH for interactive
# shells but which is usually absent from the environment rake itself runs in, so a
# bare `which` lookup isn't enough on its own.
def rustup_bin
  return which('rustup') if which('rustup')

  candidate = File.join(CARGO_BIN_DIR, 'rustup')
  File.executable?(candidate) ? candidate : nil
end

namespace :rust do
  task all: [:install]

  desc 'Install rustup and the stable Rust toolchain'
  task :install do
    if (rustup = rustup_bin)
      puts "rustup already installed at #{rustup}, skipping the installer".yellow
    else
      puts 'Install: rustup'.green
      # --no-modify-path keeps the installer out of the managed .zshrc; it still writes
      # ~/.cargo/env, which zshrc.d/rust.zsh sources to put ~/.cargo/bin on PATH.
      sh "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | " \
         'sh -s -- -y --no-modify-path --default-toolchain stable'
    end
  end

  task :update do
    if (rustup = rustup_bin)
      puts 'Update: rustup'.green
      sh(RUST_NON_PAGING_ENV, "#{rustup} self update < /dev/null")
      puts 'Update: rust toolchains'.green
      sh(RUST_NON_PAGING_ENV, "#{rustup} update < /dev/null")
    else
      puts 'No updates to rust performed -- rustup not found'.red
    end
  end

  desc 'Uninstall rustup and every toolchain it manages'
  task :uninstall do
    if (rustup = rustup_bin)
      sh "#{rustup} self uninstall -y"
    else
      puts 'Nothing to uninstall -- rustup not found'.yellow
    end
  end
end

task all: [:rust]
task update: ['rust:update']
