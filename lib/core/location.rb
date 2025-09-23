# frozen_string_literal: true

require_relative './errors'
require_relative './playground'
require_relative './interpolator'
require 'pathname'
require 'fileutils'
require 'yaml'

##
# The Location class manages playgrounds and template directories across the file system.
#
# It provides a high-level interface for creating, listing, and deleting playgrounds and templates,
# as well as managing the default template used for new playground creation.
#
# Attributes:
#   - playground_base: Directory where playgrounds reside.
#   - templates_base: Directory where template directories are stored.
#
# Methods:
#   - new_playground(playground_name, template_name): Creates a new playground from the specified template.
#   - destroy_playground(playground_name): Deletes the specified playground.
#   - list_playgrounds: Lists all existing playgrounds.
#   - new_template(template_name): Creates a new template directory.
#   - destroy_template(template_name): Deletes a template directory.
#   - list_templates: Lists all available templates (excluding the default template).
#   - default_template / default_template=: Get or set the default template.
#   - self.detect(starting_path): Searches upward from a starting path to locate a playgrounds directory.
#
# Constants:
#   - ILLEGAL_CHARACTERS: Characters that are not allowed in playground names.
#
# Errors raised:
#   - ArgumentError: if the playground or template name is illegal.
#   - Errors::PlaygroundExistsError: if a playground with the same name already exists.
#   - Errors::TemplateNotFoundError: if the specified template does not exist.
#   - Errors::PlaygroundNotFoundError: if the playground cannot be found during deletion.
#   - Errors::TemplateExistsError: if a template with the same name already exists.
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
  # @return [nil] This method returns nil.
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

    Dir.mkdir File.join(playground_full, '.playground')
    File.write(File.join(playground_full, '.playground', 'manifest'), YAML.dump({
                                                                                  name: playground_name,
                                                                                  template: template_name,
                                                                                  created: Time.now
                                                                                }))
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
    playground_struct = Struct.new(:name, :template, :created)
    Dir.children(@playground_base)
       .select { |dir_name| File.directory? File.join(@playground_base, dir_name) }
       .reject { |dir_name| dir_name.start_with? '.' }
       .map do |playground_name|
         info = YAML.load_file File.join(@playground_base, playground_name, '.playground/manifest'),
                               permitted_classes: [Time, Symbol]
         playground_struct.new(**info)
       rescue Errno::ENOENT
         playground_struct.new(playground_name)
       end
       .to_a
  end

  ##
  # Creates a new template directory.
  #
  # @param template_name [String] Name of the new template.
  # @return [void]
  # @raise [ArgumentError] if the template name is illegal.
  # @raise [Errors::TemplateExistsError] if a template with the same name already exists.
  #
  def new_template(template_name)
    raise ArgumentError unless Playground.name_legal? template_name
    raise Errors::TemplateExistsError, "Template #{template_name} already exists" if Dir.exist? File.join(
      @templates_base, template_name
    )

    FileUtils.mkdir_p File.join(@templates_base, template_name)
  end

  ##
  # Deletes a template directory.
  #
  # @param template_name [String] Name of the template to destroy.
  # @return [void]
  # @raise [Errors::TemplateNotFoundError] if the template does not exist.
  #
  def destroy_template(template_name)
    template_full = File.join @templates_base, template_name
    FileUtils.rm_r template_full, secure: true
  rescue Errno::ENOENT
    raise Errors::TemplateNotFoundError, "Template #{template_name} does not exist"
  end

  ##
  # Lists all available templates except the default.
  #
  # @return [Array<String>] An array of template directory names.
  #
  def list_templates
    Dir.children(@templates_base)
       .select { |dir_name| File.directory? File.join(@templates_base, dir_name) }
       .reject { |dir_name| dir_name.start_with? '.' }
       .to_a - ['default']
  end

  ##
  # Returns the name of the template currently set as the default template.
  #
  # Reads the symlink at "#{@templates_base}/default" to determine the default template.
  # @return [String, nil] The name of the default template if set, otherwise nil.
  #
  def default_template
    File.readlink(File.join(@templates_base, 'default'))
        .delete_prefix(@templates_base)
        .delete_prefix('/') # remove leading '/' if present
  rescue Errno::ENOENT
    nil
  end

  ##
  # Sets the default template.
  #
  # Creates a symlink at "#{@templates_base}/default" to point to the given template.
  # @param value [String] The name of the template to set as default.
  # @raise [Errors::TemplateNotFoundError] if the template directory does not exist.
  #
  def default_template=(value)
    default_path = File.join @templates_base, 'default'
    value_path = File.join @templates_base, value

    raise Errors::TemplateNotFoundError, "Template #{value} not found" unless File.directory?(value_path)

    File.delete default_path if File.symlink?(default_path)
    File.symlink value_path, default_path
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

      return current_path.join('playgrounds').to_s if Dir.children(current_path).include?('playgrounds')

      path_elements.pop
    end
    nil
  end
end
