# frozen_string_literal: true

require_relative '../location_provider'

class CLI
  class Template
    desc 'destroy TEMPLATE', 'Destroy the template called TEMPLATE'
    def destroy(name)
      location.destroy_template name
      say "Deleted template #{name} from #{location.playground_base}"
    end
  end
end
