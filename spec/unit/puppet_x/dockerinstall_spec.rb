# frozen_string_literal: true

require 'spec_helper'
require 'puppet_x/dockerinstall'

describe PuppetX::Dockerinstall do
  describe '.default_basedir' do
    context 'when /run directory exists' do
      before(:each) do
        allow(File).to receive(:directory?).with('/run').and_return(true)
      end

      it 'returns /run/compose' do
        expect(described_class.default_basedir).to eq('/run/compose')
      end
    end

    context 'when /run directory does not exist' do
      before(:each) do
        allow(File).to receive(:directory?).with('/run').and_return(false)
      end

      it 'returns /var/run/compose' do
        expect(described_class.default_basedir).to eq('/var/run/compose')
      end
    end
  end

  describe '.parse_yaml_safe' do
    context 'with valid YAML' do
      let(:yaml_content) do
        <<~YAML
          services:
            web:
              image: nginx:latest
        YAML
      end

      it 'parses YAML successfully' do
        result = described_class.parse_yaml_safe(yaml_content)
        expect(result).to be_a(Hash)
        expect(result['services']['web']['image']).to eq('nginx:latest')
      end
    end

    context 'with invalid YAML syntax' do
      let(:invalid_yaml) { "services:\n  web:\n    image: nginx:\n      bad indentation" }

      it 'raises Puppet::Error with message' do
        expect { described_class.parse_yaml_safe(invalid_yaml) }
          .to raise_error(Puppet::Error, %r{Unable to parse YAML:})
      end
    end

    context 'with empty YAML' do
      it 'returns nil for empty string' do
        expect(described_class.parse_yaml_safe('')).to be_nil
      end
    end
  end

  describe '.validate_yaml_syntax' do
    let(:confpath) { '/var/lib/compose/app/docker-compose.yml' }

    context 'with valid YAML hash' do
      let(:yaml_content) { { 'services' => { 'web' => {} } }.to_yaml }

      it 'does not raise error' do
        expect { described_class.validate_yaml_syntax(yaml_content, confpath) }.not_to raise_error
      end
    end

    context 'with YAML array instead of hash' do
      let(:yaml_array) { ['item1', 'item2'].to_yaml }

      it 'raises Puppet::Error' do
        expect { described_class.validate_yaml_syntax(yaml_array, confpath) }
          .to raise_error(Puppet::Error, %r{file does not contain a valid yaml hash})
      end
    end

    context 'with YAML string instead of hash' do
      let(:yaml_string) { 'just a string' }

      it 'raises Puppet::Error' do
        expect { described_class.validate_yaml_syntax(yaml_string, confpath) }
          .to raise_error(Puppet::Error, %r{file does not contain a valid yaml hash})
      end
    end

    context 'with invalid YAML' do
      let(:invalid_yaml) { "services:\n  bad: :\n    invalid" }

      it 'raises Puppet::Error' do
        expect { described_class.validate_yaml_syntax(invalid_yaml, confpath) }
          .to raise_error(Puppet::Error, %r{Unable to parse YAML:})
      end
    end
  end

  describe '.get_service' do
    let(:data) do
      {
        'services' => {
          'web' => { 'image' => 'nginx:latest' },
          'db' => { 'image' => 'postgres:13' },
        },
      }
    end

    context 'when service exists' do
      it 'returns service configuration' do
        result = described_class.get_service(data, 'web')
        expect(result).to eq({ 'image' => 'nginx:latest' })
      end
    end

    context 'when service does not exist' do
      it 'raises Puppet::Error' do
        expect { described_class.get_service(data, 'nonexistent') }
          .to raise_error(Puppet::Error, %r{Service nonexistent does not exist in configuration file})
      end
    end

    context 'when services key is missing' do
      let(:data) { { 'version' => '3' } }

      it 'raises Puppet::Error' do
        expect { described_class.get_service(data, 'web') }
          .to raise_error(Puppet::Error, %r{Service web does not exist in configuration file})
      end
    end

    context 'when services is nil' do
      let(:data) { { 'services' => nil } }

      it 'raises Puppet::Error' do
        expect { described_class.get_service(data, 'web') }
          .to raise_error(Puppet::Error, %r{Service web does not exist in configuration file})
      end
    end
  end

  describe '.validate_build_config' do
    context 'with valid build configuration (hash with context)' do
      let(:service) do
        {
          'image' => 'myapp:latest',
          'build' => {
            'context' => '.',
            'dockerfile' => 'Dockerfile',
          },
        }
      end

      it 'returns build configuration' do
        result = described_class.validate_build_config(service)
        expect(result).to eq({ 'context' => '.', 'dockerfile' => 'Dockerfile' })
      end
    end

    context 'with valid build configuration (string context)' do
      let(:service) do
        {
          'image' => 'myapp:latest',
          'build' => '.',
        }
      end

      it 'returns build string' do
        result = described_class.validate_build_config(service)
        expect(result).to eq('.')
      end
    end

    context 'when image is missing' do
      let(:service) do
        {
          'build' => { 'context' => '.' },
        }
      end

      it 'raises Puppet::Error' do
        expect { described_class.validate_build_config(service) }
          .to raise_error(Puppet::Error, %r{Service definition should contain 'image' and 'build' parameters})
      end
    end

    context 'when build is missing' do
      let(:service) do
        {
          'image' => 'myapp:latest',
        }
      end

      it 'raises Puppet::Error' do
        expect { described_class.validate_build_config(service) }
          .to raise_error(Puppet::Error, %r{Service definition should contain 'image' and 'build' parameters})
      end
    end

    context 'when build hash is missing context' do
      let(:service) do
        {
          'image' => 'myapp:latest',
          'build' => {
            'dockerfile' => 'Dockerfile',
          },
        }
      end

      it 'raises Puppet::Error' do
        expect { described_class.validate_build_config(service) }
          .to raise_error(Puppet::Error, %r{Service 'build' parameter should contain 'context' parameter})
      end
    end
  end

  describe '.validate_build_context' do
    let(:confpath) { '/var/lib/compose/myapp/docker-compose.yml' }

    context 'with Git URL (https)' do
      let(:build) { { 'context' => 'https://github.com/user/repo.git' } }

      it 'does not raise error' do
        expect { described_class.validate_build_context(build, confpath) }.not_to raise_error
      end
    end

    context 'with Git URL with branch' do
      let(:build) { { 'context' => 'https://github.com/user/repo.git#main' } }

      it 'does not raise error' do
        expect { described_class.validate_build_context(build, confpath) }.not_to raise_error
      end
    end

    context 'with invalid HTTP URL (not git)' do
      let(:build) { { 'context' => 'https://example.com/file.tar.gz' } }

      it 'raises Puppet::Error' do
        expect { described_class.validate_build_context(build, confpath) }
          .to raise_error(Puppet::Error, %r{Docker build context must be valid Git repo URL})
      end
    end

    context 'with absolute path' do
      let(:build) { { 'context' => '/opt/myapp/build' } }

      before(:each) do
        allow(Puppet::Util).to receive(:absolute_path?).with('/opt/myapp/build').and_return(true)
      end

      it 'does not raise error' do
        expect { described_class.validate_build_context(build, confpath) }.not_to raise_error
      end
    end

    context 'with relative path (becomes absolute)' do
      let(:build) { { 'context' => '.' } }

      before(:each) do
        allow(Puppet::Util).to receive(:absolute_path?).and_call_original
        allow(Puppet::Util).to receive(:absolute_path?)
          .with('/var/lib/compose/myapp').and_return(true)
      end

      it 'does not raise error' do
        expect { described_class.validate_build_context(build, confpath) }.not_to raise_error
      end
    end

    context 'with relative path resulting in absolute' do
      let(:build) { { 'context' => '../other' } }

      it 'constructs absolute path from confdir and does not raise error' do
        # File.join('/var/lib/compose/myapp', '../other') => '/var/lib/compose/myapp/../other'
        # Puppet::Util.absolute_path? returns true for paths starting with /
        expect { described_class.validate_build_context(build, confpath) }.not_to raise_error
      end
    end

    context 'when context is missing' do
      let(:build) { { 'dockerfile' => 'Dockerfile' } }

      it 'raises Puppet::Error' do
        expect { described_class.validate_build_context(build, confpath) }
          .to raise_error(Puppet::Error, %r{Service 'build' parameter should contain 'context' parameter})
      end
    end

    context 'with build as string (relative path)' do
      let(:build) { '.' }

      it 'raises Puppet::Error for missing context key' do
        expect { described_class.validate_build_context(build, confpath) }
          .to raise_error(Puppet::Error, %r{Service 'build' parameter should contain 'context' parameter})
      end
    end
  end

  describe '.validate_configuration_integrity' do
    let(:service_name) { 'web' }
    let(:confpath) { '/var/lib/compose/myapp/docker-compose.yml' }

    context 'when build is disabled' do
      let(:yaml_content) do
        {
          'services' => {
            'web' => { 'image' => 'nginx:latest' },
          },
        }.to_yaml
      end

      it 'does not validate build configuration' do
        expect { described_class.validate_configuration_integrity(yaml_content, service_name, confpath, false) }
          .not_to raise_error
      end
    end

    context 'when build is enabled with valid configuration' do
      let(:yaml_content) do
        {
          'services' => {
            'web' => {
              'image' => 'myapp:latest',
              'build' => {
                'context' => 'https://github.com/user/repo.git',
              },
            },
          },
        }.to_yaml
      end

      it 'validates successfully' do
        expect { described_class.validate_configuration_integrity(yaml_content, service_name, confpath, true) }
          .not_to raise_error
      end
    end

    context 'when build is enabled but image is missing' do
      let(:yaml_content) do
        {
          'services' => {
            'web' => {
              'build' => { 'context' => '.' },
            },
          },
        }.to_yaml
      end

      it 'raises Puppet::Error' do
        expect { described_class.validate_configuration_integrity(yaml_content, service_name, confpath, true) }
          .to raise_error(Puppet::Error, %r{Service definition should contain 'image' and 'build' parameters})
      end
    end

    context 'when build is enabled but context is missing' do
      let(:yaml_content) do
        {
          'services' => {
            'web' => {
              'image' => 'myapp:latest',
              'build' => {},
            },
          },
        }.to_yaml
      end

      it 'raises Puppet::Error' do
        expect { described_class.validate_configuration_integrity(yaml_content, service_name, confpath, true) }
          .to raise_error(Puppet::Error, %r{Service 'build' parameter should contain 'context' parameter})
      end
    end

    context 'when service does not exist' do
      let(:yaml_content) { { 'services' => {} }.to_yaml }

      it 'raises Puppet::Error' do
        expect { described_class.validate_configuration_integrity(yaml_content, service_name, confpath, false) }
          .to raise_error(Puppet::Error, %r{Service web does not exist in configuration file})
      end
    end

    context 'with invalid YAML' do
      let(:yaml_content) { 'invalid: : yaml' }

      it 'raises Puppet::Error' do
        expect { described_class.validate_configuration_integrity(yaml_content, service_name, confpath, false) }
          .to raise_error(Puppet::Error, %r{Unable to parse YAML})
      end
    end
  end
end
