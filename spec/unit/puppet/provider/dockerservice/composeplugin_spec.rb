# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:dockerservice).provider(:composeplugin) do
  describe 'version method' do
    let(:provider) { described_class.new(name: 'test') }

    context 'with Docker Compose v2 plugin output' do
      before do
        allow(provider).to receive(:docker).with('compose', 'version').and_return("Docker Compose version v2.36.1\n")
      end

      it 'extracts version 2.36.1' do
        expect(provider.version).to eq('2.36.1')
      end
    end

    context 'with Docker Compose v5 plugin output' do
      before do
        allow(provider).to receive(:docker).with('compose', 'version').and_return("Docker Compose version v5.0.2\n")
      end

      it 'extracts version 5.0.2' do
        expect(provider.version).to eq('5.0.2')
      end
    end
  end

  describe 'version regex matching' do
    let(:version_regex) { %r{version v[0-9]+\.[0-9]+\.[0-9]+} }

    it 'matches Docker Compose v2 output' do
      expect('Docker Compose version v2.36.1').to match(version_regex)
    end

    it 'matches Docker Compose v5 output' do
      expect('Docker Compose version v5.0.2').to match(version_regex)
    end

    it 'does not match invalid output' do
      expect('Usage:  docker compose [OPTIONS] COMMAND').not_to match(version_regex)
    end
  end
end
