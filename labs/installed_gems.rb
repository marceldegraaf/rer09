if File.exist?('./Rakefile')
  eval(File.read('./Rakefile'))
else
  raise 'You must run this script in a Rails directory!'
end

require 'rubygems/command'
require 'rubygems/commands/update_command'

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
  attr_reader :name, :requirements, :source, :lib, :latest_version, :version
  def initialize(gemspec)
    @name = gemspec.name
    @requirements = gemspec.requirement.requirements.collect(&:to_s)
    @source = gemspec.source
    @lib = gemspec.lib
  end

  def updateable?
    return false if available_versions.empty?
    latest_version > vendored_version
  end

  def vendored_version
    @version ||= Dir.new('./vendor/gems').entries.select{|gem| gem =~ /#{name}/}.first.split('-').last
  end

  def to_s
    "#{name} is #{version}, can be updated to #{latest_version}"
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
end

class System
  def self.gems
    Gem.source_index.collect do |gemspec|
      InstalledGem.new(gemspec)
    end
  end
end

class Project
  def self.gems
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

#puts Project.marshalled_gems
puts Project.updateable_gems
