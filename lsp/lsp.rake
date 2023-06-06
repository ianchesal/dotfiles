desc 'Install LSP servers'
task lsp: ['lsp:install']

NPMS = %w[neovim prettier].freeze
CARGOS = %w[stylua].freeze

namespace :lsp do
  task :install do
    puts 'Install: cargo-based LSP servers'.green
    CARGOS.each { |g| sh "cargo install #{g}" }
    sh 'cargo install --bins tree-sitter-cli'
    puts 'Install: npm-based LSP servers'.green
    NPMS.each { |g| sh "npm install --location=global #{g}" }
    puts 'Install: gem-based LSP servers'.green
    sh 'bundle install'
  end

  task :update do
    puts 'Update: cargo-based LSP servers'.green
    CARGOS.each { |g| sh "cargo install #{g}" }
    sh 'cargo install --bins tree-sitter-cli'
    puts 'Update: npm-based LSP servers'.green
    NPMS.each { |g| sh "npm update --location=global #{g}" }
    puts 'Update: gem-based LSP servers'.green
    sh 'bundle update'
  end

  task :clean do
    puts 'Uninstall: cargo-based LSP servers'.green
    CARGOS.each { |g| sh "cargo uninstall #{g}" }
    sh 'cargo uninstall tree-sitter-cli'
    puts 'Uninstall: npm-based LSP servers'.green
    NPMS.each { |g| sh "npm uninstall #{g}" }
    puts 'Uninstall: gem-based LSP servers'.green
    sh 'rm -f Gemfile Gemfile.lock'
    sh 'touch Gemfile Gemfile.lock'
    sh 'bundle clean --force'
    sh 'rm -f Gemfile Gemfile.lock'
    sh 'git restore Gemfile Gemfile.lock'
  end
end

task all: [:lsp]
task update: ['lsp:update']
task clean: ['lsp:clean']
