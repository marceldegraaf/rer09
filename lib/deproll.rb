require 'rubygems'
require 'rubygems/command'
require 'rubygems/commands/update_command'
# require File.dirname(__FILE__) + '/deproll/installed_gems'
# require File.dirname(__FILE__) + '/deproll/rails'

module Deproll

  def self.scan(dir)
    $deproll_dir = dir
    puts Project.new.updateable_gems
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

    attr_reader  :version

    def initialize(gemspec)
      @gemspec = gemspec
    end

    def name
      gemspec.name
    end

    def source
      gemspec.source
    end

    def lib
      gemspec.lib
    end

    def updateable?
      return false if available_versions.empty?
      latest_version > vendored_version
    end

    def to_s
      if installed?
        "#{name} is #{version}, can be updated to #{latest_version} from #{source}"
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

    def vendored_version
      @version = (installed? ? installed_version : '0')
    end

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
    end

    def installed_version
    end


    def vendored?
      vendored_gem.empty? ? false : true
    end

    def vendored_version
      vendored_gem.first.split('-').last
    end

    def vendored_gem
      @vendored_gem ||= Dir.glob(vendor_directory).select{|gem| gem =~ /\A#{name}-\w+\Z/}
    end

    def vendor_directory
      file("vendor", "gems")
    end

  end

  class System
    def self.gems
      Gem.source_index.collect do |gemspec|
        InstalledGem.new(gemspec)
      end
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

    def gemspecs
      Rails.configuration.gems
    end

    def updateable_gems
      load_rails if rails?
      gems.select(&:updateable?)
    end

  end

end
