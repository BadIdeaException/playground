# frozen_string_literal: true
require 'tty-table'
require 'fuzzy_time_ago'

class CLI
  desc 'list', 'List all playgrounds'
  def list
    say "Playgrounds in #{location.playground_base}:\n\n"
    playgrounds = location.list_playgrounds
    if playgrounds.empty?
      say 'No playgrounds found'
    else
      table = TTY::Table.new(['playground', 'template', 'created'], playgrounds.map {|pg| [pg.name, pg.template, pg.created&.fuzzy_ago] })
      say table.render(padding: [0,2]) + "\n"
    end
  end
end
