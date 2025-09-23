# frozen_string_literal: true

class CLI
  desc 'locate', 'Show the playgrounds directory that will be used'
  def locate
    path = location.playground_base
    if path
      say "Closest playgrounds location is #{path}"
    else
      say_error 'Could not find playgrounds directory'
    end
  end
end
