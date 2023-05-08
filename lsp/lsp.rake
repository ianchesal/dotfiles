desc 'Install LSP servers'
task lsp: ['lsp:install']

GEMS = %w[neovim solargraph].freeze
NPMS = %w[bash-language-server dockerfile-language-server-nodejs vscode-langservers-extracted pyright].freeze

namespace :lsp do
  task :install do
    puts 'Install: cargo-based LSP servers'.green
    sh 'cargo install taplo-cli --locked --features lsp'
    puts 'Install: npm-based LSP servers'.green
    NPMS.each { |g| sh "npm install --location=global #{g}" }
    puts 'Install: gem-based LSP servers'.green
    GEMS.each { |g| sh "gem install #{g}" }
  end

  task :update do
    # puts 'Update: cargo-based LSP servers'.green
    # sh 'cargo update --package taplo-cli'
    puts 'Update: npm-based LSP servers'.green
    NPMS.each { |g| sh "npm update --location=global #{g}" }
    puts 'Update: gem-based LSP servers'.green
    GEMS.each { |g| sh "gem update #{g}" }
  end

  task :clean do
    puts 'Uninstall: cargo-based LSP servers'.green
    sh 'cargo uninstall taplo-cli'
    puts 'Uninstall: npm-based LSP servers'.green
    NPMS.each { |g| sh "npm uninstall #{g}" }
    puts 'Uninstall: gem-based LSP servers'.green
    GEMS.each { |g| sh "gem uninstall #{g}" }
  end
end

task all: [:lsp]
task update: ['lsp:update']
task clean: ['lsp:clean']
