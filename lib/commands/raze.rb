# frozen_string_literal: true

# rubocop:disable Style/Documentation
class CLI < Thor
  desc 'raze NAME', 'Permanently delete the playground called NAME'
  def raze(name)
    location.destroy_playground name
    say "Playground #{name} deleted"
  end
end
# rubocop:enable Style/Documentation
