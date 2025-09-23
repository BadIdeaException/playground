# frozen_string_literal: true

require_relative '../../lib/core/interpolator'

describe Interpolator do
  describe '.interpolated?' do
    it 'is true if source string contains the interpolation sequence, false otherwise', :aggregate_failures do
      expect(described_class.new('{{ interpolate_me }}')).to be_interpolated
      expect(described_class.new('embedded{{ interpolation }} sequence')).to be_interpolated
      expect(described_class.new('{{no_spaces}}')).to be_interpolated
      expect(described_class.new('{{\t\tmuch_whitespace        }}')).to be_interpolated

      expect(described_class.new('plain_text')).not_to be_interpolated
    end
  end

  describe '#interpolate' do
    values = {
      a_variable: 'foo',
      another_variable: 'bar'
    }.freeze

    it 'interpolates based on the provided values' do
      result = described_class.new('embedded {{ a_variable }}{{ another_variable }} sequence').interpolate values
      expect(result).to eq 'embedded foobar sequence'
    end

    it 'handles arbitrary whitespace in the interpolation sequence' do
      result = described_class.new("{{\t\ta_variable        }}").interpolate values
      expect(result).to eq 'foo'
    end

    it 'does not interpolate missing values' do
      result = described_class.new('{{ non_existent }}').interpolate values
      expect(result).to eq '{{ non_existent }}'
    end

    it 'returns the source string if there are no interpolation sequences' do
      expect(described_class.new('plain text').interpolate(values)).to eq 'plain text'
    end

    it 'returns the source string if values is nil' do
      expect(described_class.new('{{ a_variable }}').interpolate(nil)).to eq '{{ a_variable }}'
    end
  end
end
