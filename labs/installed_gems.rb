if File.exist?('./Rakefile')
  eval(File.read('./Rakefile'))
else
  raise 'You must run this script in a Rails directory!'
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
  attr_accessor :name, :requirements, :source, :lib
  def initialize(gemspec)
    @name = gemspec.name
    @requirements = gemspec.requirement.requirements.collect(&:to_s)
    @source = gemspec.source
    @lib = gemspec.lib
  end

  def updateable?
    
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

  def self.marshalled_gems
    Marshal.dump(gems)
  end
end

puts Project.marshalled_gems
