# frozen_string_literal: true

require_relative './errors'
require_relative './playground'
require_relative './interpolator'
require 'pathname'

##
# The `Location` class encapsulates a place where playgrounds are kept.
# Within the "playground" metaphor, you might think of it as a city park,
# that contains multiple individual playgrounds.
#
# This class acts as the high-level interface for working with playgrounds.
# Specifically, it manages the creation and destruction of playgrounds
# based on predefined templates.
#
# A *playground* is a working directory generated from a template. The
# Location keeps track of where playgrounds and templates are stored, and
# ensures that new playgrounds are created legally and consistently.
#
# === Attributes
# * +playground_base+ - The base directory where all playgrounds are created.
# * +templates_base+  - The base directory where all templates are stored.
#
# === Constants
# * +ILLEGAL_CHARACTERS+ - Characters not allowed in playground names.
#
# === Methods
# - +new_playground(playground_name, template_name)+::
#   Creates a new playground directory from a template.
#   * Raises ArgumentError if the playground name is illegal.
#   * Raises Errors::PlaygroundExistsError if the playground already exists.
#   * Raises Errors::TemplateNotFoundError if the template does not exist.
#   * Copies all files from the template to the new playground.
#   * Interpolates placeholder sequences (e.g. {{ playground }}, {{ template }})
#     in filenames and file contents.
#   * Rewrites symlinks that pointed to the template so they now point to the
#     corresponding paths in the new playground.
#
# - +destroy_playground(playground_name)+::
#   Destroys an existing playground directory.
#   * Raises Errors::PlaygroundNotFoundError if the playground does not exist.
#
# - +list_playgrounds+::
#   Returns a list of all playground directory names.
#
# - +self.detect(starting_path)+::
#   Detects the absolute path of the playgrounds directory starting
#   from a given path.
#
class Location
  attr_reader :playground_base, :templates_base

  ILLEGAL_CHARACTERS = ['/'].freeze

  ##
  # Initializes a new Location.
  #
  # @param playground_base [String] The base directory where playgrounds are created.
  # @param templates_base [String] The base directory where templates are stored.
  def initialize(playground_base, templates_base)
    @playground_base = playground_base
    @templates_base = templates_base
  end

  ##
  # Creates a new playground from a given template.
  #
  # This method:
  # * Copies the template contents into the new playground directory.
  # * Interpolates placeholders (e.g., {{ playground }}, {{ template }})
  #   in file names and contents.
  # * Rewrites symlinks that pointed into the template so they point
  #   into the new playground instead.
  #
  # @param playground_name [String] Name of the new playground.
  # @param template_name [String] Name of the template to base it on.
  # @return [Playground] The newly created Playground instance.
  #
  # @raise [ArgumentError] if the playground name is illegal.
  # @raise [Errors::PlaygroundExistsError] if a playground with the same
  #   name already exists.
  # @raise [Errors::TemplateNotFoundError] if the template does not exist.
  #
  def new_playground(playground_name, template_name)
    raise ArgumentError unless Playground.name_legal? playground_name

    playground_full = File.join @playground_base, playground_name
    template_full = File.join @templates_base, template_name

    raise Errors::PlaygroundExistsError, "Playground #{playground_name} already exists" if Dir.exist? playground_full
    raise Errors::TemplateNotFoundError, "Template #{template_name} not found" unless Dir.exist? template_full

    FileUtils.cp_r template_full, playground_full, preserve: false

    interpolation_values = {
      playground: playground_name,
      template: template_name
    }

    # Interpolate file names
    # Rubocop keeps wanting to combine these loops, because it doesn't understand that the file names change in here
    # rubocop:disable Style/CombinableLoops
    Dir.each_child(playground_full) do |entry_name|
      interpolator = Interpolator.new entry_name
      next unless interpolator.interpolated?

      new_name = interpolator.interpolate interpolation_values
      File.rename File.join(playground_full, entry_name), File.join(playground_full, new_name)
    end

    # Interpolate file contents
    Dir.each_child(playground_full) do |entry_name|
      entry_name = File.join playground_full, entry_name
      contents = File.read entry_name
      interpolator = Interpolator.new contents

      new_contents = interpolator.interpolate interpolation_values

      File.write(entry_name, new_contents) unless new_contents == contents
    end

    # Redirect symlinks to targets inside the template to be inside their counterparts in the new playground
    Dir.each_child(playground_full) do |entry_name|
      entry_name = File.join playground_full, entry_name
      next unless File.symlink?(entry_name) && (link_target = File.readlink(entry_name)).start_with?(template_full)

      new_target = link_target.sub template_full, playground_full
      File.delete entry_name
      File.symlink new_target, entry_name
    end
    # rubocop:enable Style/CombinableLoops
    nil
  end

  ##
  # Destroys the playground directory.
  #
  # @param playground_name [String] The name of the playground to destroy.
  # @raise [Errors::PlaygroundNotFoundError] if the playground does not exist.
  def destroy_playground(playground_name)
    playground_full = File.join @playground_base, playground_name
    FileUtils.rm_r(playground_full, secure: true)
  rescue Errno::ENOENT
    raise Errors::PlaygroundNotFoundError, "Playground #{playground_name} does not exist"
  end

  ##
  # Lists all playground directories.
  #
  # @return [Array<String>] An array of playground directory names.
  def list_playgrounds
    Dir.children(@playground_base)
       .select { |dir_name| File.directory? File.join(@playground_base, dir_name) }
       .reject { |dir_name| dir_name.start_with? '.' }
       .to_a
  end

  ##
  # Detects and returns the absolute path to the playgrounds directory by
  # searching upward from the given starting path.
  #
  # @param starting_path [String] The path to start the search.
  # @return [String, nil] The absolute path if found, otherwise nil.
  def self.detect(starting_path)
    path_elements = [''] + Pathname.new(starting_path).each_filename.to_a

    until path_elements.empty?
      current_path = Pathname.new('/').join(*path_elements)

      return current_path.join('playgrounds').to_s if current_path.directory? && Dir.children(current_path).include?('playgrounds')

      path_elements.pop
    end
    nil
  end
end
