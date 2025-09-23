Gem::Specification.new do |spec|
  spec.name          = "playground"
  spec.version       = "0.0.0"
  spec.authors       = ["BadIdeaException"]

  spec.summary       = %q{playground is a command-line tool to quickly create and otherwise manage throwaway coding environments.}
  spec.description   = %q{`playground` is a command-line tool to quickly create and otherwise manage playgrounds - throwaway coding environments to isolate bugs, try proof of concepts, or try out ideas.}
  spec.homepage      = "https://github.com/BadIdeaException/playground"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "bin/*", "README.md"]
  spec.bindir        = "bin"
  spec.executables   = ["playground"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "thor", "~> 1.0"
  spec.add_runtime_dependency 'fuzzy_time_ago'
  spec.add_runtime_dependency 'tty-table', '~>0.12.0'

  spec.add_development_dependency 'fakefs'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'timecop'
end
