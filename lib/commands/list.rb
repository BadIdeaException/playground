# frozen_string_literal: true
require 'tty-table'

# rubocop:disable Style/Documentation
class CLI < Thor
  desc 'list', 'List all playgrounds'
  def list
    say "Playgrounds in #{location.playground_base}:\n\n"
    playgrounds = location.list_playgrounds
    if playgrounds.empty?
      say 'No playgrounds found'
    else
      table = TTY::Table.new playgrounds.map(&:values)
      say table.render
      #say playgrounds.join('\n')
    end
  end
end
# rubocop:enable Style/Documentation
