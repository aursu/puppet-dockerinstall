require 'spec_helper'

describe 'dockerinstall::tls' do
  let(:pre_condition) { 'include dockerinstall' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_file('/etc/docker/tls/ca.pem')
          .with_source('file:///etc/puppetlabs/puppet/ssl/certs/ca.pem')
      }

      it {
        is_expected.to contain_file('/etc/docker/tls/cert.pem')
          .with_source('file:///etc/puppetlabs/puppet/ssl/certs/steves-macbook-pro.local.pem')
      }

      it {
        is_expected.to contain_file('/etc/docker/tls/key.pem')
          .with_source('file:///etc/puppetlabs/puppet/ssl/private_keys/steves-macbook-pro.local.pem')
          .with_mode('0400')
      }

      context 'with TLS access to other system users' do
        let(:params) do
          {
            users_access: true,
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
