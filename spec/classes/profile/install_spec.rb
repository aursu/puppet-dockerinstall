require 'spec_helper'

describe 'dockerinstall::profile::install' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_file('/etc/docker/tls')
          .with_ensure('directory')
          .with_mode('0700')
      }

      context 'with TLS access to other system users' do
        let(:params) do
          {
            tls_users_access: true,
          }
        end

        it {
          is_expected.to contain_file('/etc/docker/tls')
            .with_ensure('directory')
            .with_mode('0711')
        }
      end
    end
  end
end
