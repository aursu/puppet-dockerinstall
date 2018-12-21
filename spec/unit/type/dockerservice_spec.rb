#! /usr/bin/env ruby
require 'spec_helper'
require 'yaml'

describe Puppet::Type.type(:dockerservice) do
  it 'check fail  with empty configuration' do
    params = {
      title: 'rpmbuild-curl/centos7curlbuild',
      configuration: '{}'
    }
    expect { described_class.new(params) }.to raise_error(Puppet::Error, %r{Service centos7curlbuild does not exist in configuration file})
  end

  context 'check title_patterns' do
    before(:each) do
      File.stubs(:directory?).with('/run').returns(false)
      @service = described_class.new(
        title: 'rpmbuild-curl/centos6curlbuild',
        configuration: { 'services' => { 'centos6curlbuild' => {} } }.to_yaml,
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
    it 'check /run' do
      File.stubs(:directory?).with('/run').returns(true)
      service = described_class.new(
        title: 'curl/centos7curlbuild',
        configuration: { 'services' => { 'centos7curlbuild' => {} } }.to_yaml,
      )
      expect(service[:path]).to eq('/run/compose/curl/docker-compose.yml')
    end
    it 'check /var/run' do
      File.stubs(:directory?).with('/run').returns(false)
      service = described_class.new(
        title: 'curl/centos6curlbuild',
        configuration: { 'services' => { 'centos6curlbuild' => {} } }.to_yaml,
      )
      expect(service[:path]).to eq('/var/run/compose/curl/docker-compose.yml')
    end
  end

  context 'check project' do
    before(:each) do
      File.stubs(:directory?).with('/run').returns(false)
      @service = described_class.new(
        title: 'curl/centos6curlbuild',
        configuration: { 'services' => { 'centos6curlbuild' => {} } }.to_yaml,
      )
    end

    it 'check title_patterns override with full path' do
      @service[:project] = '/var/lib/build/rpmbuild-curl'
      expect(@service[:project]).to eq('rpmbuild-curl')
      expect(@service[:basedir]).to eq('/var/lib/build')
    end

    it 'check title_patterns override with project name' do
      @service[:project] = 'rpmbuild-curl'
      expect(@service[:project]).to eq('rpmbuild-curl')
      expect(@service[:basedir]).to eq('/var/run/compose')
    end
  end

  context 'check path' do
    before(:each) do
      File.stubs(:directory?).with('/run').returns(false)
      @service = described_class.new(
        title: 'curl/centos6curlbuild',
        configuration: { 'services' => { 'centos6curlbuild' => {} } }.to_yaml,
      )
    end

    it 'check default path' do
      expect(@service[:path]).to eq('/var/run/compose/curl/docker-compose.yml')
    end

    it 'check absolute path' do
      @service[:path] = '/var/lib/build/rpmbuild-curl/docker-compose.yml'
      expect(@service[:path]).to eq('/var/lib/build/rpmbuild-curl/docker-compose.yml')
      expect(@service[:project]).to eq('curl')
      expect(@service[:basedir]).to eq('/var/run/compose')
    end

    it 'check conflict with project full path' do
      params = {
        title: 'curl/centos6curlbuild',
        project: '/var/run/compose/rpmbuild-curl',
        path: '/var/lib/build/rpmbuild-curl/docker-compose.yml',
        configuration: { 'services' => { 'centos6curlbuild' => {} } }.to_yaml
      }
      expect { described_class.new(params) }.to raise_error(Puppet::Error, %r{Path should be relative to project directory \(/var/run/compose/rpmbuild-curl\) - not absolute})
    end
  end

  context 'should be able to autorequire' do
    before(:each) do
      @catalog = Puppet::Resource::Catalog.new
      @configuration = { 'services' => { 'centos7curlbuild' => {} } }.to_yaml
    end

    it 'default basedir (/var/run/compose)' do
      basedir = Puppet::Type.type(:file).new(name: '/var/run/compose')
      @catalog.add_resource basedir

      service = Puppet::Type.type(:dockerservice).new(
        title:         'rpmbuild-curl/centos7curlbuild',
        configuration: @configuration,
      )
      @catalog.add_resource service
      dependencies = service.autorequire(@catalog)

      expect(dependencies.map(&:to_s)).to eq([Puppet::Relationship.new(basedir, service).to_s])
    end

    it 'custom basedir' do
      basedir = Puppet::Type.type(:file).new(name: '/var/lib/build')
      @catalog.add_resource basedir

      service = Puppet::Type.type(:dockerservice).new(
        title:         'curl/centos7curlbuild',
        project:       '/var/lib/build/rpmbuild-curl',
        configuration: @configuration,
      )
      @catalog.add_resource service

      dependencies = service.autorequire(@catalog)

      expect(dependencies.map(&:to_s)).to eq([Puppet::Relationship.new(basedir, service).to_s])
    end
  end
end
