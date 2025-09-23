# frozen_string_literal: true

require_relative '../location_provider'

class CLI
  class Template
    desc 'new TEMPLATE', 'Create a new template called TEMPLATE'
    def new_template(name)
      location.new_template name
      say "Created template #{name} in #{location.playground_base}"
    end
  end
end
