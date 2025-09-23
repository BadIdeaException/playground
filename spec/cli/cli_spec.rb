# frozen_string_literal: true

require_relative '../../lib/cli/cli'
require_relative '../../lib/core/location'

describe CLI do
  subject(:cli) { described_class.new }

  let(:location) { instance_spy(Location) }

  before do
    ctx = self
    described_class.class_exec do
      # rubocop:disable RSpec/AnyInstance
      no_commands { ctx.allow_any_instance_of(self).to ctx.receive(:location).and_return ctx.location }
      # rubocop:enable RSpec/AnyInstance
    end
  end

  after do
    described_class.class_exec do
      no_commands { RSpec::Mocks.teardown }
    end
  end

  describe 'playground new NAME [-t TEMPLATE]' do
    it 'uses the specified name' do
      expect do
        cli.invoke(:new_playground, ['example_playground'])
      end.to output(/playground example_playground/i).to_stdout
      expect(location).to have_received(:new_playground).with 'example_playground', anything
    end

    it 'uses the specified template' do
      expect do
        cli.invoke(:new_playground, ['example_playground'], template: 'example_template')
      end.to output(/from template example_template/).to_stdout
      expect(location).to have_received(:new_playground).with anything, 'example_template'
    end

    it 'uses the default template if none is specified' do
      expect do
        cli.invoke(:new_playground, ['example_playground'])
      end.to output(/from default template/).to_stdout
      expect(location).to have_received(:new_playground).with anything, 'default'
    end

    it 'errors when no name is specified' do
      expect do
        cli.invoke(:new_playground)
      end.to raise_error(Thor::InvocationError)
    end
  end

  describe 'playground raze NAME' do
    it 'uses the specified name' do
      expect do
        cli.invoke(:raze, ['example_playground'])
      end.to output(/example_playground/).to_stdout
      expect(location).to have_received(:destroy_playground).with 'example_playground'
    end

    it 'errors when no name is specified' do
      expect do
        cli.invoke(:raze)
      end.to raise_error(Thor::InvocationError)
    end
  end

  describe 'playground list' do
    before do
      allow(TTY::Screen).to receive(:width).and_return(80)
    end

    it 'prints all playgrounds to stdout' do
      playground_struct = Struct.new(:name, :template, :created)
      allow(location).to receive(:list_playgrounds).and_return [
        playground_struct.new('playground_1', 'template_1', Time.now),
        playground_struct.new('playground_2', 'template_2', Time.now)
      ]
      expected_output = /playground_1\s+template_1\s+less than a minute ago.*playground_2\s+template_2\s+less than a minute ago/m

      expect { cli.invoke(:list) }.to output(expected_output).to_stdout
    end

    it 'prints "No playgrounds found" to stdout if there are no playgrounds' do
      allow(location).to receive(:list_playgrounds).and_return []
      expect { cli.invoke(:list) }.to output(/No playgrounds found/).to_stdout
    end
  end

  describe described_class::Template do
    subject(:cli_template) { described_class.new }

    describe 'list' do
      it 'prints all templates to stdout' do
        templates = %w[template_1 template_2]
        allow(location).to receive_messages(list_templates: templates, default_template: nil)
        expect { cli_template.invoke(:list) }.to output(/template_1.*template_2/m).to_stdout
      end

      it 'prints "No templates found" to stdout if there are no templates' do
        allow(location).to receive(:list_templates).and_return []
        expect { cli_template.invoke(:list) }.to output(/No templates found/).to_stdout
      end
    end

    describe 'default' do
      it 'prints the current default playground when not given a parameter' do
        allow(location).to receive(:default_template).and_return('example_template')
        expect { cli_template.invoke(:default) }.to output(/example_template/).to_stdout
        expect(location).to have_received(:default_template).with(no_args)
      end

      it 'prints "Default playground not set" when given no parameter and there is no default playground' do
        allow(location).to receive(:default_template).and_return(nil)
        expect { cli_template.invoke(:default) }.to output(/not set/).to_stdout
        expect(location).to have_received(:default_template).with(no_args)
      end

      it 'sets a new default playground when given a name' do
        allow(location).to receive(:default_template=)
        expect { cli_template.invoke(:default, ['example_template']) }.to output(/example_template/).to_stdout
        expect(location).to have_received(:default_template=).with('example_template')
      end
    end

    describe 'new' do
      it 'uses the specified name' do
        allow(location).to receive(:new_template)
        expect { cli_template.invoke(:new_template, ['example_template']) }.to output(/example_template/i).to_stdout
        expect(location).to have_received(:new_template).with('example_template')
      end

      it 'errors when no name is specified' do
        expect { cli.invoke(:new_template) }.to raise_error(Thor::InvocationError)
        expect(location).not_to have_received(:new_template)
      end
    end

    describe 'destroy' do
      it 'uses the specified name' do
        allow(location).to receive(:destroy_template)
        expect { cli_template.invoke(:destroy, ['example_template']) }.to output(/example_template/i).to_stdout
        expect(location).to have_received(:destroy_template).with('example_template')
      end

      it 'errors when no name is specified' do
        expect { cli.invoke(:destroy) }.to raise_error(Thor::InvocationError)
        expect(location).not_to have_received(:destroy_template)
      end
    end
  end
end
