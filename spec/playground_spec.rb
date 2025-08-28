# frozen_string_literal: true

require_relative '../lib/playground'

describe Playground do
  describe 'name_legal?' do
    it 'is false if the playground name is not a legal file name', :aggregate_failures do
      expect(described_class).not_to be_name_legal('playground*')
      expect(described_class).not_to be_name_legal('playground/')
    end

    it 'is false if the playground name includes illegal characters', :aggregate_failures do
      Playground::ILLEGAL_CHARACTERS.each do |illegal_character|
        expect(described_class).not_to be_name_legal("playground#{illegal_character}")
      end
    end

    it 'if false if the playground name starts with a dot' do
      expect(described_class).not_to be_name_legal('.playground')
    end

    it 'is false if the playground name contains interpolation sequences ({{}})' do
      expect(described_class).not_to be_name_legal('{{ playground }}')
    end

    it 'is true otherwise', :aggregate_failures do
      [
        'playground',
        'playground_with_underscores',
        'playground.with.dots',
        'playground-with-dashes',
        'playgroundWithNumbers123'
      ].each { |playground_name| expect(described_class).to be_name_legal(playground_name) }
    end
  end
end
