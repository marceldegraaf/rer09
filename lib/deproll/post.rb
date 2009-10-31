require 'httparty'
require 'yaml'

module Deproll

  class Post

    attr_reader :gems
    include HTTParty

    def initialize(gems)
      @gems = gems
    end

    def post
      self.class.base_uri(config['base_uri'])
      self.class.post(config['url'], config['options'])
    end

    def dependencies
      gems.each(&:to_hash)
    end

    def config
      YAML.load_file("~/deproll.yml")
    end

    def options
      { :dependencies => dependencies,
        :stage        => config['stage'],
        :project      => config['project'] }
    end

  end

end