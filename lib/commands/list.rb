class CLI < Thor
  desc 'list', 'List all playgrounds'
  def list
    say "Playgrounds in #{location.playground_base}:\n\n"
    playgrounds = location.list_playgrounds
    unless playgrounds.empty?
      say playgrounds.join('\n')
    else
      say "No playgrounds found"
    end
  end
end