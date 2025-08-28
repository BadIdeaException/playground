# frozen_string_literal: true

require 'timecop'
require 'fakefs/spec_helpers'
require_relative '../lib/location'
require_relative '../lib/errors'

PLAYGROUND_BASE = '/playgrounds'
PLAYGROUND = 'example_playground'
PLAYGROUND_FULL = File.join PLAYGROUND_BASE, PLAYGROUND

TEMPLATE_BASE = File.join PLAYGROUND_BASE, '.templates'
TEMPLATE = 'example_template'
TEMPLATE_FULL = File.join TEMPLATE_BASE, TEMPLATE

TEMPLATE_FILES = {
  "basic.txt": 'basic',
  "{{ playground }}.txt": 'playground',
  "{{ template }}.txt": 'template',
  "interpolated.txt": 'foo{{ playground }}foo{{ template }}foo'
}.freeze

describe Location do
  include FakeFS::SpecHelpers

  subject(:location) { described_class.new PLAYGROUND_BASE, TEMPLATE_BASE }

  before do
    Timecop.freeze
    FileUtils.mkdir_p(TEMPLATE_FULL)
    TEMPLATE_FILES.each_pair { |filename, contents| File.write(File.join(TEMPLATE_FULL, filename.to_s), contents) }
    File.symlink File.join(TEMPLATE_FULL, 'basic.txt'), File.join(TEMPLATE_FULL, 'symlink')
  end

  after do
    Timecop.return
  end

  describe '#new_playground' do
    it 'creates a folder with the name of the playground' do
      location.new_playground PLAYGROUND, TEMPLATE

      expect(Dir).to exist PLAYGROUND_FULL
    end

    it 'copies all files from the template to the new playground' do
      location.new_playground PLAYGROUND, TEMPLATE
      expect(Dir.new(PLAYGROUND_FULL)
        .children
        # Need to filter due to bug https://github.com/fakefs/fakefs/issues/515
        .reject { |filename| ['.', '..'].include?(filename) }
        .length).to eq TEMPLATE_FILES.length + 1
    end

    it 'sets file dates to current', :aggregate_failures do
      new_time = Time.now + 24 * 60 * 60 # Advance clock by one day
      Timecop.freeze new_time

      location.new_playground PLAYGROUND, TEMPLATE

      Dir.each_child(PLAYGROUND_FULL) do |child|
        expect(File.atime(File.join(PLAYGROUND_FULL, child))).to eq new_time
        expect(File.mtime(File.join(PLAYGROUND_FULL, child))).to eq new_time
      end
    end

    it 'interpolates filenames' do
      location.new_playground PLAYGROUND, TEMPLATE

      expect(File).to exist File.join(PLAYGROUND_FULL, "#{PLAYGROUND}.txt")
      expect(File).not_to exist File.join(PLAYGROUND_FULL, '{{ playground }}.txt')

      expect(File).to exist File.join(PLAYGROUND_FULL, "#{TEMPLATE}.txt")
      expect(File).not_to exist File.join(PLAYGROUND_FULL, '{{ template }}.txt')
    end

    it 'interpolates file contents' do
      location.new_playground PLAYGROUND, TEMPLATE

      contents = File.read File.join(PLAYGROUND_FULL, 'interpolated.txt')
      expected = "foo#{PLAYGROUND}foo#{TEMPLATE}foo"

      expect(contents).to eq(expected)
    end

    it 'redirects symlinks with target inside the template to be inside the new playground' do
      location.new_playground PLAYGROUND, TEMPLATE

      filename = File.join PLAYGROUND_FULL, 'symlink'
      expect(File).to be_symlink filename
      expect(File.readlink(filename)).to eq File.join(PLAYGROUND_FULL, 'basic.txt')
    end

    it 'leaves the template unchanged' do
      location.new_playground PLAYGROUND, TEMPLATE
      TEMPLATE_FILES.each_pair do |filename, contents|
        filename = File.join TEMPLATE_FULL, filename.to_s

        expect(File.read(filename)).to eq contents
      end
    end

    it 'fails if the playground already exists' do
      Dir.mkdir PLAYGROUND_FULL

      expect { location.new_playground PLAYGROUND, TEMPLATE }.to raise_error Errors::PlaygroundExistsError
    end

    it 'fails if playground name includes illegal characters', :aggregate_failures do
      Playground::ILLEGAL_CHARACTERS.each do |illegal_character|
        expect { location.new_playground(PLAYGROUND + illegal_character, TEMPLATE) }.to raise_error ArgumentError
      end
    end

    it 'fails if the playground name starts with a dot' do
      expect { location.new_playground(".#{PLAYGROUND}", TEMPLATE) }.to raise_error ArgumentError
    end

    it 'fails if the playground name contains interpolation sequences ({{}})' do
      expect { location.new_playground '{{ playground }}', TEMPLATE }.to raise_error ArgumentError
    end

    it 'fails if the template doesn\'t exist' do
      expect { location.new_playground PLAYGROUND, 'nonexistent' }.to raise_error Errors::TemplateNotFoundError
    end
  end

  describe '#destroy_playground' do
    before do
      Dir.mkdir PLAYGROUND_FULL
    end

    it 'deletes the folder with the name of the playground' do
      location.destroy_playground PLAYGROUND
      expect(Dir).not_to exist(PLAYGROUND_FULL)
    end

    it 'fails if the playground doesn\'t exist' do
      expect { location.destroy_playground 'nonexistent' }.to raise_error Errors::PlaygroundNotFoundError
    end
  end

  describe '#list_playgrounds' do
    it 'lists all folders in the playground base location' do
      playgrounds = %w[example_playground_1 example_playground_2]
      playgrounds.each { |playground| Dir.mkdir File.join(PLAYGROUND_BASE, playground) }

      expect(location.list_playgrounds).to match_array playgrounds
    end

    it 'does not list hidden folders' do
      playground = '.hidden_folder'
      Dir.mkdir File.join(PLAYGROUND_BASE, playground)

      expect(location.list_playgrounds).not_to include playground
    end

    it 'does not list files and symlinks' do
      File.write File.join(PLAYGROUND_BASE, 'file'), 'foo'
      File.symlink 'file', File.join(PLAYGROUND_BASE, 'symlink')

      expect(location.list_playgrounds).to exclude('file', 'symlink')
    end
  end
end
