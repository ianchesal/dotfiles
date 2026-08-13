# frozen_string_literal: true

desc 'Install all asdf dotfiles'
task asdf: ['asdf:all']

# Versions asdf accepts that Gem::Version can't order (`system`, `ref:<sha>`,
# `jruby-9.4.5.0`, ...). These are never pruned: without an ordering there's no way to
# know they're older than what's in use.
def asdf_comparable?(version)
  Gem::Version.correct?(version)
end

# Versions pinned in ~/.tool-versions, as { plugin => [versions] }. A line may list
# several versions (asdf tries them left to right), so every version on it is in use.
def asdf_pinned_versions
  path = home('.tool-versions')
  return {} unless File.exist?(path)

  File.readlines(path).each_with_object({}) do |line, pinned|
    plugin, *versions = line.sub(/#.*/, '').split
    pinned[plugin] = versions unless plugin.nil? || versions.empty?
  end
end

# Versions of a plugin installed on this machine. asdf flags the version in use with a
# leading `*` and reports "no compatible versions installed" on stderr, so stdout parses
# cleanly and an empty result just means nothing is installed.
def asdf_installed_versions(plugin)
  `asdf list #{plugin} 2>/dev/null`.lines.map { |line| line.strip.delete_prefix('*') }.reject(&:empty?)
end

# Everything installed for a plugin that is strictly older than the oldest version in
# use. An unpinned plugin falls back to its newest install, which collapses it to a
# single version rather than leaving it untouched. A pin we can't order (`ref:<sha>`)
# disables pruning for that plugin entirely.
def asdf_prunable_versions(in_use, installed)
  return [] unless in_use.all? { |version| asdf_comparable?(version) }

  threshold = in_use.map { |version| Gem::Version.new(version) }.min
  installed.select { |version| asdf_comparable?(version) && Gem::Version.new(version) < threshold }
end

# What a single plugin contributes to the uninstall plan, or nil when it has nothing
# installed.
def asdf_plan_entry(plugin, pinned)
  installed = asdf_installed_versions(plugin)
  return if installed.empty?

  comparable = installed.select { |version| asdf_comparable?(version) }
  in_use = pinned.fetch(plugin, Array(comparable.max_by { |version| Gem::Version.new(version) }))
  { plugin: plugin,
    in_use: in_use,
    pinned: pinned.key?(plugin),
    prune: asdf_prunable_versions(in_use, installed),
    skipped: installed - comparable }
end

# The uninstall plan, one entry per installed plugin.
def asdf_prune_plan
  pinned = asdf_pinned_versions
  `asdf plugin list`.split.filter_map { |plugin| asdf_plan_entry(plugin, pinned) }
end

# One-line headline for a plugin, e.g. "ruby: using 4.0.6, 11 to remove".
def asdf_plan_summary(entry)
  in_use = entry[:in_use].empty? ? 'no version in use' : "using #{entry[:in_use].join(', ')}"
  in_use += ' (unpinned, keeping newest)' unless entry[:pinned]
  removals = entry[:prune].empty? ? 'nothing to remove' : "#{entry[:prune].size} to remove"
  "#{entry[:plugin]}: #{in_use}, #{removals}"
end

def report_asdf_prune_plan(plan)
  plan.each do |entry|
    summary = asdf_plan_summary(entry)
    puts entry[:prune].empty? ? summary.green : summary.yellow
    entry[:prune].each { |version| puts "  - #{version}" }
    entry[:skipped].each { |version| puts "  ? #{version} (uncomparable version, left alone)".gray }
  end
end

def asdf_confirm(prompt)
  print "#{prompt} [y/N] "
  answer = $stdin.gets
  !answer.nil? && answer.strip.casecmp('y').zero?
end

# Whether to go ahead with the uninstalls, saying why when we don't. FORCE=1 skips the prompt.
def asdf_prune_confirmed?(plan)
  total = plan.sum { |entry| entry[:prune].size }
  if total.zero?
    puts 'Nothing to remove'.green
    return false
  end
  return true if ENV['FORCE'] == '1' || asdf_confirm("Uninstall #{total} tool versions?")

  puts 'Aborted'.red
  false
end

namespace :asdf do
  task all: [:asdf]

  # Depends on rust:install because ruby-build only compiles YJIT/ZJIT into Ruby when a
  # Rust toolchain is present at build time, and `rake all` would otherwise reach asdf first.
  task asdf: ['rust:install'] do
    dolink(home('.asdfrc'), root('asdf', 'asdfrc'))
    dolink(home('.tool-versions'), root('asdf', 'tool-versions'))
    sh 'asdf plugin add ruby || true'
    sh 'asdf plugin add nodejs || true'
    sh 'asdf plugin add golang || true'
    sh 'asdf install ruby'
    sh 'asdf install nodejs'
    sh 'asdf install golang'
  end

  task :update do
    puts 'Update: asdf'.green
    # This is no longer supported
    # sh 'asdf update'
    puts 'Update: asdf plugins'.green
    sh 'asdf plugin update --all'
  end

  desc 'Show the tool versions rake asdf:prune would uninstall'
  task :prune_preview do
    report_asdf_prune_plan(asdf_prune_plan)
  end

  # Deliberately not named asdf:cleanup: it would sit one keystroke away from asdf:clean,
  # which only unlinks dotfiles, and a typo there would uninstall toolchains.
  desc 'Uninstall tool versions older than the version in use (FORCE=1 skips the prompt)'
  task :prune do
    plan = asdf_prune_plan
    report_asdf_prune_plan(plan)
    next unless asdf_prune_confirmed?(plan)

    plan.each do |entry|
      entry[:prune].each { |version| sh "asdf uninstall #{entry[:plugin]} #{version}" }
    end
  end

  task :clean do
    sh "rm -f #{home('.tool-versions')}"
    clean_restore home('.asdfrc')
  end
end

task all: [:asdf]
task update: ['asdf:update']
task clean: ['asdf:clean']
