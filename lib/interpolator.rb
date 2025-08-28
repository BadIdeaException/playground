# frozen_string_literal: true

class Interpolator
  INTERPOLATION_SEQUENCE = /\{\{.*\}\}/.freeze

  attr_reader :source

  def initialize(source)
    @source = source.to_s
  end

  def interpolated?
    @source =~ INTERPOLATION_SEQUENCE
  end

  def interpolate(values)
    return @source if values.nil?

    values.each_pair.reduce(@source) do |acc, (pattern, value)|
      pattern = /\{\{\s*#{pattern}\s*\}\}/
      acc.gsub pattern, value
    end
  end
end
