# frozen_string_literal: true
require_relative '../location_provider'

class CLI::Template
  desc 'destroy TEMPLATE', 'Destroy the template called TEMPLATE'
  def destroy(name)
    location.destroy_template name
    say "Template #{name} destroyed"
  end
end
