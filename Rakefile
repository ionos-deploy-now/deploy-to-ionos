# frozen_string_literal: true
ENV['gem_push']  = 'off'

require 'bundler/gem_tasks'
require 'rake/version_task'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :build

Rake::VersionTask.new
