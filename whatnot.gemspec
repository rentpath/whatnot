# -*- encoding: utf-8 -*-
require File.expand_path('../lib/whatnot/version', __FILE__)

Gem::Specification.new do |s|
  s.name = "whatnot"
  s.version = Whatnot::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tyler Boyd"]
  s.autorequire = "whatnot"
  s.date = "2015-07-23"
  s.description = "Fast constraint solver with user-friendly API"
  # s.executables = ["git-changelog"]
  s.extra_rdoc_files = ["README.md", "LICENSE"]
  s.files = `git ls-files`.split("\n")
  s.homepage = ""
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "Fast constraint solver with user-friendly API"

  s.add_development_dependency('rake', '>= 0.8.7')
  s.add_development_dependency('rspec', '>= 1.3.0')
end
