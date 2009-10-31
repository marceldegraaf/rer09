require 'rubygems'
require File.dirname(__FILE__) + '/deproll/installed_gems'
require File.dirname(__FILE__) + '/deproll/rails'

module Deproll

  def self.scan(dir)
    Deproll::InstalledGems.scan(dir)
    Deproll::Rails.scan(dir) if File.exist?(dir + '/config/environment.rb')
  end

end
