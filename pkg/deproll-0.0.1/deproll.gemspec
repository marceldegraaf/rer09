# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{deproll}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Iain Hecker"]
  s.date = %q{2009-10-31}
  s.default_executable = %q{deproll}
  s.description = %q{Integration Gem Managment and Webistrano}
  s.email = %q{iain@iain.nl}
  s.executables = ["deproll"]
  s.extra_rdoc_files = ["README", "bin/deproll", "lib/deproll.rb"]
  s.files = ["README", "Rakefile", "bin/deproll", "labs/format.txt", "labs/installed_gems.rb", "lib/deproll.rb", "Manifest", "deproll.gemspec"]
  s.homepage = %q{http://github.com/Thyraon/rer09}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Deproll", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{deproll}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Integration Gem Managment and Webistrano}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
