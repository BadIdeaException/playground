# frozen_string_literal: true

require 'thor'
require_relative 'location_provider'

# Playgrounds CLI skeleton class.
# Commands are added from commands folder
class CLI < Thor
  include LocationProvider

  def self.exit_on_failure?
    true
  end

  Dir[File.join(__dir__, 'commands', '*.rb')].sort.each do |command|
    require_relative(command)
  end
end
