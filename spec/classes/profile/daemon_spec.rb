require 'spec_helper'

describe 'dockerinstall::profile::daemon' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      # this check is major for daemon profile
      it {
        is_expected.to contain_package('docker')
          .with_name('docker-ce')
          .that_notifies('Service[docker]')
      }

      it {
        is_expected.to contain_file('/etc/docker/daemon.json')
          .that_notifies('Service[docker]')
      }

      context 'with TLS access to other system users' do
        let(:params) do
          {
            tls_users_access: true,
          }
        end

        it {
          is_expected.to contain_file('/etc/docker/tls/key.pem')
            .with_source('file:///etc/puppetlabs/puppet/ssl/private_keys/steves-macbook-pro.local.pem')
            .with_mode('0644')
        }
      end
    end
  end
end
