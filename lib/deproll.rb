require 'rubygems'
require 'rubygems/command'
require 'rubygems/commands/update_command'
# require File.dirname(__FILE__) + '/deproll/installed_gems'
# require File.dirname(__FILE__) + '/deproll/rails'

module Deproll

  def self.scan(dir)
    $deproll_dir = dir
    puts Project.updateable_gems
  end


  class InstalledGem
    attr_accessor :name, :version, :dependencies

    def initialize(gemspec)
      gemspec = gemspec.last
      @name = gemspec.name
      @version = gemspec.version
      @dependencies = gemspec.requirements.collect(&:first) #returns the name of a gem, e.g. 'fastthread' for Passenger
    end
  end

  class ProjectGem
    attr_reader :name, :source, :lib, :latest_version, :version
    def initialize(gemspec)
      @name = gemspec.name
      @source = gemspec.source
      @lib = gemspec.lib
    end

    def updateable?
      return false if available_versions.empty?
      latest_version > vendored_version
    end

    def vendored_version
      @version = (installed? ? installed_version : '0')
    end

    def to_s
      if installed?
        "#{name} is #{version}, can be updated to #{latest_version}"
      else
        "#{name} is not yet installed. Version #{latest_version} is available."
      end
    end

    private

    def dependency
      @dependency ||= Gem::Dependency.new(name, "> #{vendored_version}")
    end

    def fetcher
      @fetcher ||= Gem::SpecFetcher.fetcher
    end

    def available_versions
      @available_versions ||= fetcher.find_matching(dependency).map(&:flatten).map(&:second).map(&:version)
    end

    def latest_version
      @latest_version = available_versions.last
    end

    def installed?
      vendored_gem.empty? ? false : true
    end

    def installed_version
      @version = vendored_gem.first.split('-').last
    end

    def vendored_gem
      @vendored_gem ||= Dir.new('./vendor/gems').entries.select{|gem| gem =~ /#{name}/}
    end
  end

  class System
    def self.gems
      Gem.source_index.collect do |gemspec|
        InstalledGem.new(gemspec)
      end
    end
  end

  class Project

    def self.read_rakefile
      file = File.join($deproll_dir, "Rakefile")
      eval(File.read(file)) if File.exist?(file)
    end

    def self.gems
      read_rakefile
      $gems_rake_task = true
      require 'rubygems/gem_runner'
      Rake::Task[:environment].invoke
      Rails.configuration.gems.collect{|gemspec| ProjectGem.new(gemspec)}.flatten
    end

    def self.updateable_gems
      gems.select(&:updateable?)
    end

    def self.marshalled_gems
      Marshal.dump(gems)
    end

  end

end
