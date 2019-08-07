# # -*- encoding: utf-8 -*-
# frozen_string_literal: true
require File.expand_path('../lib/version', __FILE__)

Gem::Specification.new do |s|
  s.name = "facter-statistax"
  s.version = FacterStatistax::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [""]
  s.date = "2019-08-08"
  s.description = "Benchmark for facter"
  s.email = ""
  s.executables = ["statistax"]
  s.files = `git ls-files `.split("\n")
  s.homepage = ""
  s.rdoc_options = ["--title", "Facter-Statistax ", "--main", "README", "--line-numbers"]
  s.require_paths = ["bin"]
  s.rubyforge_project = "facter-statistax"
  s.summary = "Facter-Statistax, benchmark for facter"

  s.add_dependency('logger', ["< 1.4.0"])
  s.add_dependency 'fileutils'
  s.add_dependency 'rubysl-open3'
  s.add_dependency 'json'
end