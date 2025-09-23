# frozen_string_literal: true

require_relative './interpolator'

##
# The Playground class represents a single playground: a
# disposable working directory created from a template for
# quickly experimenting with code.
#
# Playgrounds are initialized from templates, which provide
# a preconfigured project structure (for example, Node.js,
# Python, or a full-stack environment). Each playground
# is self-contained, can be freely modified, and can be
# destroyed without affecting other playgrounds or their
# templates.
#
# === Intended Responsibilities
# * Encapsulate the identity and path of a playground.
# * Provide helpers for validating playground names
#   (e.g. {Playground.name_legal?}).
# * Offer instance-level operations such as:
#   - Locating the playground on disk.
#   - Interacting with files inside the playground.
#   - Managing the lifecycle of the playground (in
#     conjunction with {Location}).
#
# === Future Extensions
# The Playground class may grow to handle:
# * Tracking the template it was created from.
# * Exposing metadata about the playground (e.g. language,
#   stack type, creation time).
# * Providing convenience methods for resetting, reloading,
#   or snapshotting playgrounds.
#
# The {Location} class is responsible for creating and
# destroying playgrounds at the filesystem level. Playground
# instances provide an object-oriented handle for working
# with them after they exist.
#
class Playground
  ILLEGAL_CHARACTERS = ['/', '*', '?'].freeze

  def self.name_legal?(playground_name)
    (!playground_name.start_with? '.') &&
      self::ILLEGAL_CHARACTERS.all? { |illegal_character| !playground_name.include? illegal_character } &&
      playground_name !~ Interpolator::INTERPOLATION_SEQUENCE
  end
end
