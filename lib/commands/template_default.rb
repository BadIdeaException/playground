# frozen_string_literal: true
require_relative '../location_provider'

class CLI::Template
  desc 'default TEMPLATE', 'Set the default template to TEMPLATE. If TEMPLATE is not given, prints the current default template'
  def default(template_name = nil)
    if template_name
      location.default_template = template_name      
      say "Default template set to #{template_name}"
    else
      if default_template = location.default_template
        say "Default template: #{default_template}"
      else
        say "Default template not set"
      end
    end
  end
end
