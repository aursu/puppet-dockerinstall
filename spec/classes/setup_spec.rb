# frozen_string_literal: true

require 'spec_helper'

describe 'dockerinstall::setup' do
  let(:pre_condition) { 'include dockerinstall' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_file('/etc/docker')
          .with_ensure('directory')
      }

      it {
        is_expected.to contain_file('/etc/docker/certs.d')
          .with_ensure('directory')
          .with_mode('0700')
      }

      it {
        is_expected.to contain_file('/etc/docker/tls')
          .with_ensure('directory')
          .with_mode('0700')
      }

      context 'with TLS access to other system users' do
        let(:params) do
          {
            users_access: true,
          }
        end
        it {
          is_expected.to contain_file('/etc/docker/tls')
            .with_ensure('directory')
            .with_mode('0711')
        }
      end

      context 'with docker directory removal' do
        let(:params) do
          {
            docker_dir_ensure: 'absent',
          }
        end
        it {
          is_expected.to contain_file('/etc/docker')
            .with_ensure('absent')
        }
      end
    end
  end
end
