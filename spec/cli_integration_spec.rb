require 'fakefs/spec_helpers'
require 'yaml'
require 'timecop'
require_relative '../lib/cli'
require 'stringio'

PLAYGROUNDS_DIR = '/some/location/playgrounds'

RSpec.describe CLI, :type => 'integration' do
  include FakeFS::SpecHelpers
  
  before do
    templates_dir = File.join(PLAYGROUNDS_DIR, '.templates')
    FileUtils.mkdir_p PLAYGROUNDS_DIR
    FileUtils.mkdir_p templates_dir

    # Create a sample template named 'example_template'
    template_dir = File.join templates_dir, 'example_template'
    Dir.mkdir(template_dir)
    File.write(File.join(template_dir, 'file.txt'), "Hello template: {{ template }}, playground: {{ playground }}")
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
      output = capture_stdout { CLI.start(['list']) }
      expect(output).to match(/existing_playground/)
    end

    it 'creates a new playground with the "new" command' do
      output = capture_stdout do
        Timecop.freeze do
          expect {
            CLI.start(['new', 'test_playground', '-t', 'example_template'])
          }.to change { Dir.exist?(File.join(PLAYGROUNDS_DIR, 'test_playground')) }.from(false).to(true)

          playground_content_file = File.join PLAYGROUNDS_DIR, 'test_playground', 'file.txt'
          expect(File).to exist(playground_content_file)
          expect(File.read(File.join PLAYGROUNDS_DIR, 'test_playground', 'file.txt')).to eq 'Hello template: example_template, playground: test_playground'

          manifest_path = File.join(PLAYGROUNDS_DIR, 'test_playground', '.playground', 'manifest')
          expect(File.exist?(manifest_path)).to be true

          manifest = YAML.load_file(manifest_path, permitted_classes: [Time,Symbol])
          expect(manifest).to eq Hash[name: 'test_playground', template: 'example_template', created: Time.now]
        end 
      end

      expect(output).to match(/playground test_playground created from template example_template/i)
    end

    it 'destroys an existing playground with the "raze" command' do
      # Create a playground to be destroyed.
      Dir.mkdir(File.join(PLAYGROUNDS_DIR, 'to_be_deleted'))
      output = capture_stdout { CLI.start(['raze', 'to_be_deleted']) }

      expect(Dir.exist?(File.join(PLAYGROUNDS_DIR, 'to_be_deleted'))).to be false
      expect(output).to match(/playground to_be_deleted deleted/i)
    end
  end

  describe 'when no playgrounds directory is found' do
    it 'raises an error during CLI invocation' do
      Dir.chdir(PLAYGROUNDS_DIR) do
        # Remove the playgrounds directory temporarily.
        FileUtils.rm_rf(PLAYGROUNDS_DIR)
        expect {
          CLI.start(['list'])
        }.to raise_error(/Could not find a playgrounds directory/)
      end
    end
  end
end
