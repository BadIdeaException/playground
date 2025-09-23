# frozen_string_literal: true

require_relative '../location_provider'

class CLI
  class Template
    desc 'list', 'List all templates'
    def list
      say "Templates in #{location.playground_base}:\n\n"
      templates = location.list_templates
      if templates.empty?
        say 'No templates found'
      else
        table = TTY::Table.new(%w[template], [:separator] + templates.map { |x| [x] })
        say "#{table.render(padding: [0, 2])}\n"
      end
    end
  end
end
