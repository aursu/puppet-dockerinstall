#! /usr/bin/env ruby
require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:dockerservice) do
  let(:basedir) { Puppet::Type.type(:file).new(name: '/var/run/compose') }
  let(:catalog) { Puppet::Resource::Catalog.new }

  before(:each) do
    catalog.add_resource basedir
    allow(File).to receive(:directory?).with('/run').and_return(false)
  end

  it 'check fail  with empty configuration' do
    params = {
      title: 'rpmbuild-curl/centos7curlbuild',
      configuration: '{}',
      catalog: catalog,
    }
    expect { described_class.new(params) }.to raise_error(RuntimeError, %r{Service centos7curlbuild does not exist in configuration file})
  end

  context 'when title_patterns' do
    before(:each) do
      @service = described_class.new(
        title: 'rpmbuild-curl/centos6curlbuild',
        configuration: { 'services' => { 'centos6curlbuild' => {} } }.to_yaml,
        catalog: catalog,
      )
    end
    it 'check project' do
      expect(@service[:project]).to eq('rpmbuild-curl')
    end
    it 'check service name' do
      expect(@service[:name]).to eq('centos6curlbuild')
    end
    it 'check default path to docker compose file' do
      expect(@service[:path]).to eq('/var/run/compose/rpmbuild-curl/docker-compose.yml')
    end
  end

  context 'check basedir' do
    it 'when rundir is /run' do
      catalog.add_resource Puppet::Type.type(:file).new(name: '/run/compose')
      allow(File).to receive(:directory?).with('/run').and_return(true)
      service = described_class.new(
        title: 'curl/centos7curlbuild',
        configuration: { 'services' => { 'centos7curlbuild' => {} } }.to_yaml,
        catalog: catalog,
      )
      expect(service[:path]).to eq('/run/compose/curl/docker-compose.yml')
    end

    it 'when rundir is /var/run' do
      service = described_class.new(
        title: 'curl/centos6curlbuild',
        configuration: { 'services' => { 'centos6curlbuild' => {} } }.to_yaml,
        catalog: catalog,
      )
      expect(service[:path]).to eq('/var/run/compose/curl/docker-compose.yml')
    end

    it 'when project path specified' do
      catalog.add_resource Puppet::Type.type(:file).new(name: '/root/compose')
      service = described_class.new(
        title: 'curl/centos6curlbuild',
        configuration: { 'services' => { 'centos6curlbuild' => {} } }.to_yaml,
        project: '/root/compose/apollo11',
        catalog: catalog,
      )
      expect(service[:basedir]).to eq('/root/compose')
      expect(service[:project]).to eq('apollo11')
      expect(service[:path]).to eq('/root/compose/apollo11/docker-compose.yml')
    end

    it 'when both project path and basedir specified' do
      catalog.add_resource Puppet::Type.type(:file).new(name: '/root/compose')
      catalog.add_resource Puppet::Type.type(:file).new(name: '/root/moon/missions')
      service = described_class.new(
        title: 'curl/centos6curlbuild',
        configuration: { 'services' => { 'centos6curlbuild' => {} } }.to_yaml,
        project: '/root/compose/apollo11',
        basedir: '/root/moon/missions',
        catalog: catalog,
      )
      expect(service[:basedir]).to eq('/root/moon/missions')
      expect(service[:project]).to eq('apollo11')
      expect(service[:path]).to eq('/root/moon/missions/apollo11/docker-compose.yml')
    end
  end

  context 'check project' do
    before(:each) do
      @service = described_class.new(
        title: 'curl/centos6curlbuild',
        configuration: { 'services' => { 'centos6curlbuild' => {} } }.to_yaml,
        catalog: catalog,
      )
    end

    it 'when title_patterns overriden with full path' do
      catalog.add_resource Puppet::Type.type(:file).new(name: '/var/lib/build')
      @service[:project] = '/var/lib/build/rpmbuild-curl'
      expect(@service[:project]).to eq('rpmbuild-curl')
      expect(@service[:basedir]).to eq('/var/lib/build')
    end

    it 'when title_patterns overriden with project name' do
      @service[:project] = 'rpmbuild-curl'
      expect(@service[:project]).to eq('rpmbuild-curl')
      expect(@service[:basedir]).to eq('/var/run/compose')
    end
  end

  context 'check path' do
    before(:each) do
      @service = described_class.new(
        title: 'curl/centos6curlbuild',
        configuration: { 'services' => { 'centos6curlbuild' => {} } }.to_yaml,
        catalog: catalog,
      )
    end

    it 'when default path' do
      expect(@service[:path]).to eq('/var/run/compose/curl/docker-compose.yml')
    end

    it 'when absolute path' do
      catalog.add_resource Puppet::Type.type(:file).new(name: '/var/lib/build/rpmbuild-curl')
      @service[:path] = '/var/lib/build/rpmbuild-curl/docker-compose.yml'
      expect(@service[:path]).to eq('/var/lib/build/rpmbuild-curl/docker-compose.yml')
      expect(@service[:project]).to eq('curl')
      expect(@service[:basedir]).to eq('/var/run/compose')
    end

    it 'when conflict with project full path' do
      params = {
        title: 'curl/centos6curlbuild',
        project: '/var/run/compose/rpmbuild-curl',
        path: '/var/lib/build/rpmbuild-curl/docker-compose.yml',
        configuration: { 'services' => { 'centos6curlbuild' => {} } }.to_yaml,
        catalog: catalog,
      }
      expect { described_class.new(params) }.to raise_error(Puppet::Error, %r{Path should be relative to project directory \(/var/run/compose/rpmbuild-curl\) - not absolute})
    end
  end

  context 'check build' do
    let(:params) do
      {
        title: 'curl/centos6curlbuild',
        configuration: { 'services' => { 'centos6curlbuild' => {} } }.to_yaml,
        build: true,
        catalog: catalog,
      }
    end

    context 'when no build/image properties are set' do
      it {
        expect { described_class.new(params) }.to raise_error(Puppet::Error, %r{Service definition should contain 'image' and 'build' parameters})
      }
    end

    context 'when no context is set' do
      let(:params) do
        super().merge(
          configuration: {
            'services' => {
              'centos6curlbuild' => {
                'image' => 'centos6curlbuild',
                'build' => {},
              },
            },
          }.to_yaml,
        )
      end

      it {
        expect { described_class.new(params) }.to raise_error(Puppet::Error, %r{Service 'build' parameter should contain 'context' parameter})
      }
    end
  end

  context 'check resource validation' do
    it 'with missed project directory file resource' do
      params = {
        title: 'curl/centos6curlbuild',
        path: '/var/lib/build/rpmbuild-curl/docker-compose.yml',
        configuration: { 'services' => { 'centos6curlbuild' => {} } }.to_yaml,
        catalog: catalog,
      }
      expect { described_class.new(params) }.to raise_error(Puppet::Error, %r{File resource for configuration base path /var/lib/build/rpmbuild-curl not found})
    end
  end

  context 'should be able to autorequire' do
    let(:configuration) { { 'services' => { 'centos7curlbuild' => {} } }.to_yaml }

    it 'with default basedir (/var/run/compose)' do
      service = Puppet::Type.type(:dockerservice).new(
        title:         'rpmbuild-curl/centos7curlbuild',
        configuration: configuration,
        catalog:       catalog,
      )
      catalog.add_resource service
      dependencies = service.autorequire(catalog)

      expect(dependencies.map(&:to_s)).to eq([Puppet::Relationship.new(basedir, service).to_s])
    end

    context 'with custom basedir' do
      let(:basedir) { Puppet::Type.type(:file).new(name: '/var/lib/build') }

      it 'service autorequire basedir' do
        service = Puppet::Type.type(:dockerservice).new(
          title:         'curl/centos7curlbuild',
          project:       '/var/lib/build/rpmbuild-curl',
          configuration: configuration,
          catalog:       catalog,
        )
        catalog.add_resource service
        dependencies = service.autorequire(catalog)

        expect(dependencies.map(&:to_s)).to eq([Puppet::Relationship.new(basedir, service).to_s])
      end
    end
  end
end
