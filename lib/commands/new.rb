# frozen_string_literal: true

# rubocop:disable Style/Documentation
class CLI
  desc 'new NAME', 'Create a new playground called NAME'
  method_option :template, aliases: '-t', desc: 'template to use'
  def new_playground(name)
    template = options[:template] || 'default'

    location.new_playground name, template
    say "Playground #{name} created from " + (options[:template] ? "template #{template}" : 'default template')
  end
end
# rubocop:enable Style/Documentation
