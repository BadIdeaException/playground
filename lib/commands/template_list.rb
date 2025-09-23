# frozen_string_literal: true

require_relative '../location_provider'

class CLI
  class Template
    desc 'list', 'List all templates'
    def list
      say 'Templates:'
      templates = location.list_templates
      if templates.empty?
        say 'No templates found'
      else
        say templates.join("\n")
      end
    end
  end
end
