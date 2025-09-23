# frozen_string_literal: true

class CLI
  desc 'raze NAME', 'Permanently delete the playground called NAME'
  def raze(name)
    location.destroy_playground name
    say "Deleted playground #{name} from #{location.playground_base}"
  end
end
