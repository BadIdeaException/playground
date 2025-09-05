# frozen_string_literal: true

require 'thor'
require_relative 'location'
Dir[File.join(__dir__, 'commands', '*.rb')].sort.each do |command|
  require_relative(command)
end

# Playgrounds CLI skeleton class.
# Commands are added from commands folder
class CLI < Thor
  def self.exit_on_failure?
    true
  end

  no_commands do
    def location
      unless @location
        path = Location.detect Dir.pwd
        throw 'Could not find a playgrounds directory' if path.nil?
        @location = Location.new path, File.join(path, '.templates')
      end
      @location
    end
  end
end
