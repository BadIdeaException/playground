# frozen_string_literal: true

require 'fakefs/spec_helpers'
require 'yaml'
require 'timecop'
require_relative '../lib/cli'
require 'stringio'

PLAYGROUNDS_DIR = '/some/location/playgrounds'
TEMPLATES_DIR = File.join(PLAYGROUNDS_DIR, '.templates')

RSpec.describe CLI, type: 'integration' do
  include FakeFS::SpecHelpers

  before do
    FileUtils.mkdir_p PLAYGROUNDS_DIR
    FileUtils.mkdir_p TEMPLATES_DIR

    # Create a sample template named 'example_template'
    template_dir = File.join TEMPLATES_DIR, 'example_template'
    Dir.mkdir(template_dir)
    File.write(File.join(template_dir, 'file.txt'), 'Hello template: {{ template }}, playground: {{ playground }}')
    allow(TTY::Screen).to receive(:width).and_return(80)
  end

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    result = $stdout.string
    $stdout = original_stdout
    result
  end

  describe 'when operating in a valid playgrounds directory' do
    before { Dir.chdir(PLAYGROUNDS_DIR) }

    it 'lists existing playgrounds' do
      # Create a playground directory manually to test the list command.
      Dir.mkdir(File.join(PLAYGROUNDS_DIR, 'existing_playground'))
      output = capture_stdout { described_class.start(['list']) }
      expect(output).to match(/existing_playground/)
    end

    it 'creates a new playground with the "new" command' do
      output = capture_stdout do
        Timecop.freeze do
          expect do
            described_class.start(['new', 'test_playground', '-t', 'example_template'])
          end.to change { Dir.exist?(File.join(PLAYGROUNDS_DIR, 'test_playground')) }.from(false).to(true)

          playground_content_file = File.join PLAYGROUNDS_DIR, 'test_playground', 'file.txt'
          expect(File).to exist(playground_content_file)
          expect(File.read(File.join(PLAYGROUNDS_DIR, 'test_playground',
                                     'file.txt'))).to eq 'Hello template: example_template, playground: test_playground'

          manifest_path = File.join(PLAYGROUNDS_DIR, 'test_playground', '.playground', 'manifest')
          expect(File.exist?(manifest_path)).to be true

          manifest = YAML.load_file(manifest_path, permitted_classes: [Time, Symbol])
          expect(manifest).to eq Hash[name: 'test_playground', template: 'example_template', created: Time.now]
        end
      end

      expect(output).to match(/playground test_playground created from template example_template/i)
    end

    it 'destroys an existing playground with the "raze" command' do
      # Create a playground to be destroyed.
      Dir.mkdir(File.join(PLAYGROUNDS_DIR, 'to_be_deleted'))
      output = capture_stdout { described_class.start(%w[raze to_be_deleted]) }

      expect(Dir.exist?(File.join(PLAYGROUNDS_DIR, 'to_be_deleted'))).to be false
      expect(output).to match(/playground to_be_deleted deleted/i)
    end

    it 'lists templates with the "template list" command' do
      # Template example_template was already created during before
      output = capture_stdout { described_class.start(%w[template list]) }
      expect(output).to match(/example_template/)
    end

    it 'creates a new template with the "template new" command' do
      output = capture_stdout { described_class.start(%w[template new new_template]) }

      expect(Dir).to exist File.join(TEMPLATES_DIR, 'new_template')
      expect(output).to match(/created/).and match(/new_template/)
    end

    it 'destroys an existing template with the "template destroy" command' do
      output = capture_stdout { described_class.start(%w[template destroy example_template]) }

      expect(Dir).not_to exist File.join(TEMPLATES_DIR, 'example_template')
      expect(output).to match(/destroyed/i).and match(/example_template/)
    end

    it 'shows the default template with the "template default" command without args' do
      output = capture_stdout { described_class.start(%w[template default]) }
      expect(output).to match(/not set/)

      File.symlink File.join(TEMPLATES_DIR, 'example_template'), File.join(TEMPLATES_DIR, 'default')

      output = capture_stdout { described_class.start(%w[template default]) }
      expect(output).to match(/example_template/)
    end

    it 'sets the default template with the "template default" command with args' do
      output = capture_stdout { described_class.start(%w[template default example_template]) }

      expect(File).to be_symlink(File.join(TEMPLATES_DIR, 'default'))
      expect(File.readlink(File.join(TEMPLATES_DIR, 'default'))).to eq File.join(TEMPLATES_DIR, 'example_template')
      expect(output).to match(/set to/).and match(/example_template/)
    end
  end

  describe 'when no playgrounds directory is found' do
    it 'raises an error during CLI invocation' do
      Dir.chdir(PLAYGROUNDS_DIR) do
        # Remove the playgrounds directory temporarily.
        FileUtils.rm_rf(PLAYGROUNDS_DIR)
        expect do
          described_class.start(['list'])
        end.to raise_error(/Could not find a playgrounds directory/)
      end
    end
  end
end
