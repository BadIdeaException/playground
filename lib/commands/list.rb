# frozen_string_literal: true

# rubocop:disable Style/Documentation
class CLI < Thor
  desc 'list', 'List all playgrounds'
  def list
    say "Playgrounds in #{location.playground_base}:\n\n"
    playgrounds = location.list_playgrounds
    if playgrounds.empty?
      say 'No playgrounds found'
    else
      say playgrounds.join('\n')
    end
  end
end
# rubocop:enable Style/Documentation
