# frozen_string_literal: true
#
# This class provides utility methods for interpolating placeholders in strings.
#
class Interpolator
  INTERPOLATION_SEQUENCE = /\{\{.*\}\}/.freeze

  attr_reader :source

  ##
  # Creates a new Interpolator instance.
  #
  # @param source [String] The string to perform interpolation on.
  def initialize(source)
    @source = source.to_s
  end

  ##
  # Checks if the source string contains any interpolation placeholders.
  #
  # @return [Boolean] true if a placeholder is found, false otherwise.
  def interpolated?
    !!(@source =~ INTERPOLATION_SEQUENCE)
  end

  ##
  # Interpolates the source string by replacing placeholders with provided values.
  #
  # @param values [Hash] A hash where keys are placeholder names and values are their replacements.
  # @return [String] The interpolated string.
  def interpolate(values)
    return @source if values.nil?

    values.each_pair.reduce(@source) do |acc, (pattern, value)|
      pattern = /\{\{\s*#{pattern}\s*\}\}/
      acc.gsub pattern, value
    end
  end
end
