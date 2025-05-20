# frozen_string_literal: true

require 'spec_helper'

describe 'dockerinstall::registry::base' do
  let(:pre_condition) do
    <<-PRECOND
    class { 'dockerinstall': }
    class { 'dockerinstall::compose': }
    PRECOND
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
        }
      end

      it { is_expected.to compile }

      it {
        is_expected.to contain_dockerservice('registry/registry')
          .with(
            'ensure' => 'running',
            'basedir' => '/var/lib/compose',
            'project' => 'registry',
            'build' => false,
          )
          .without_path
        
        is_expected.to contain_dockerservice('registry/registry')
          .with_configuration(%r{- 5000:5000})

        is_expected.to contain_dockerservice('registry/registry')
          .with_configuration(%r{REGISTRY_STORAGE_DELETE_ENABLED: "true"})
      }

      context 'when build image requested' do
        let(:params) do
          super().merge(
            'accesslog_disabled' => true,
          )
        end

        it {
          is_expected.to contain_dockerservice('registry/registry')
            .with(
              'ensure' => 'running',
              'basedir' => '/var/lib/compose',
              'project' => 'registry',
              'build' => false,
            )
            .without_path
            .with_configuration(%r{REGISTRY_LOG_ACCESSLOG_DISABLED: "true"})
        }
      end
    end
  end
end
