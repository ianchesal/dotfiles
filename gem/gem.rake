desc 'Install all gem-related dotfiles'
task gem: ['gem:all']

namespace :gem do
  task all: [:gemrc]

  task gemrc: [:gemdir] do
    dolink(home('.gemrc'), root('gem', 'gemrc'))
  end

  task :gemdir do
    mkdir_if_needed home('.gem')
  end

  desc 'Remove old gem versions and uninstall default gem conflicts'
  task :cleanup do
    if ENV['WORK_MACHINE']
      puts 'Skipping gem cleanup on work machine (WORK_MACHINE is set)'.yellow
      next
    end

    puts 'Update: gem cleanup'.green
    sh 'gem cleanup'

    # Collect gems pinned in any Gemfile.lock so we don't remove bundler-managed versions.
    locked = Dir['**/Gemfile.lock'].flat_map do |lockfile|
      content = File.read(lockfile)
      gems = content.scan(/^\s{4}(\S+) \(([^)]+)\)/).map { |name, ver| "#{name}-#{ver}" }
      # BUNDLED WITH names the required bundler version outside the gem stanza.
      bundler_ver = content[/^BUNDLED WITH\n\s+(\S+)/, 1]
      gems << "bundler-#{bundler_ver}" if bundler_ver
      gems
    end.to_set

    # Find gems where both an installed version AND a default version exist.
    # Having both causes Gem::Specification to emit "Unresolved or ambiguous specs"
    # warnings on every bundle run. Only remove versions not pinned by a Gemfile.lock.
    conflicts = `gem list`.scan(/^(\S+)\s+\(([^)]+)\)/).select do |_name, versions|
      versions.include?('default:')
    end

    conflicts.each do |name, versions|
      installed = versions.split(/,\s*/).reject { |v| v.start_with?('default:') }.map(&:strip)
      installed.each do |version|
        if locked.include?("#{name}-#{version}")
          puts "Skipping #{name} #{version} (pinned in Gemfile.lock)".blue
        else
          puts "Removing #{name} #{version} (conflicts with default gem)".yellow
          sh "gem uninstall #{name} --version '#{version}' --ignore-dependencies"
        end
      end
    end
  end

  desc 'Update bundled gems and clean up gem conflicts'
  task :update do
    puts 'Update: bundle update'.green
    sh 'bundle update'
    Rake::Task['gem:cleanup'].invoke
  end

  task :clean do
    clean_restore home('.rubocop.yml')
  end
end

task all: [:gem]
task clean: ['gem:clean']
task update: ['gem:update']
