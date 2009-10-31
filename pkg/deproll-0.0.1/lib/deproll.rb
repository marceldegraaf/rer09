require 'rubygems'
require 'rubygems/command'
require 'rubygems/commands/update_command'
require 'httparty'
 
module Deproll

  def self.scan(dir)
    $deproll_dir = dir
    gems = RailsEnvironment.new.updateable_gems
    puts gems
    puts "Sending to Webistrano..."
    Post.new(gems).post
  end

 
  class Post
 
    attr_reader :gems

    include HTTParty
    base_uri 'webistrano.local' # sorry hardcoded yet
 
    def initialize(gems)
      @gems = gems
    end
 
    def post
      puts options.inspect
      self.class.post('/projects/1/stages/1/dependencies', :query => options) # again hard coded
    end
 
    def dependencies
      gems.map(&:to_hash)
    end
 
    def options
      { :dependencies => dependencies }
    end
 
  end
 
  module Helper

    def file(*segments)
      File.join(*[$deproll_dir] << segments)
    end

  end

  class InstalledGem

    attr_accessor :gemspec

    def initialize(gemspec)
      @gemspec = gemspec.last
    end

    def dependencies
      requirements.collect(&:first) #returns the name of a gem, e.g. 'fastthread' for Passenger
    end

    def method_missing(method, *args, &block)
      if gemspec.respond_to?(method)
        gemspec.send(method, *args, &block)
      else
        super
      end
    end

  end

  class ProjectGem

    include Helper

    attr_reader :gemspec

    def initialize(gemspec)
      @gemspec = gemspec
    end

    def to_hash
      { :name               => name.to_s,
        :current_version    => version.to_s,
        :available_version  => latest_version.to_s,
        :source             => source.to_s,
        :lib                => lib.to_s,
        :requirement        => requirement.to_s }
    end

    def requirement
      gemspec.requirement
    end

    def name
      gemspec.name
    end

    def source
      gemspec.source || Gem.sources.first
    end

    def lib
      gemspec.lib
    end

    def updateable?
      return false if available_versions.empty?
      latest_version > version
    end

    def to_s
      case
        when vendored? then  "#{name} is #{version} (vendored), can be updated to #{latest_version} from #{source}"
        when installed? then "#{name} is #{version} (installed), can be updated to #{latest_version} from #{source}"
      else
        "#{name} is not yet installed. Version #{latest_version} is available on #{source}"
      end
    end

    def version
      case
        when vendored? then vendored_version
        when installed? then installed_version
        else
          '0'
        end
    end

    private

    def dependency
      @dependency ||= Gem::Dependency.new(name, "> #{version}")
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
      installed_versions.any?
    end

    def installed_version
      installed_versions.last.last.version.version
    end

    def vendored?
      !vendored_gem.empty?
    end

    def vendored_version
      vendored_gem.first.split('-').last
    end

    def vendored_gem
      @vendored_gem ||= Dir.new(vendor_directory).entries.select{|gem| gem =~ /\A#{name}-[\w|.]+\z/}
    end

    def vendor_directory
      file("vendor", "gems")
    end

    def installed_versions
      @installed_gems ||= Gem.source_index.select{|gem| gem.last.name == name}
    end

  end

  class RailsEnvironment

    include Helper

    def rails?
      File.exist?(file("config", "environment.rb"))
    end

    def rakefile
      file("Rakefile")
    end

    def rakefile?
      File.exist?(rakefile)
    end

    def load_rails
      puts "Loading Rails..."
      eval(File.read(rakefile))
      $gems_rake_task = true
      require 'rubygems/gem_runner'
      Rake::Task[:environment].invoke
    end

    def gems
      gemspecs.map { |gemspec| ProjectGem.new(gemspec) }.flatten
    end

    def dependencies(gem)
      ([gem] + gem.dependencies.map { |dp| dependencies(dp) }.flatten).flatten
    end

    def gemspecs
      Rails.configuration.gems.map do |gem|
        [gem] + dependencies(gem)
      end.flatten.uniq
    end

    def updateable_gems
      load_rails if rails?
      gems.select(&:updateable?)
    end

  end

end
