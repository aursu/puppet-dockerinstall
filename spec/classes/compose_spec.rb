require 'spec_helper'

describe 'dockerinstall::compose' do
  let(:pre_condition) { 'include dockerinstall' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_exec('docker-compose-checksum')
          .with_command('curl -L https://github.com/docker/compose/releases/download/v2.2.2/docker-compose-linux-x86_64.sha256 -o docker-compose-linux-x86_64.sha256.2.2.2')
          .with_unless('grep docker-compose-linux-x86_64 /tmp/docker-compose-linux-x86_64.sha256.2.2.2')
      }

      it {
        is_expected.to contain_exec('docker-compose-download')
          .with_command('curl -L https://github.com/docker/compose/releases/download/v2.2.2/docker-compose-linux-x86_64 -o docker-compose-linux-x86_64')
          .with_unless('sha256sum -c docker-compose-linux-x86_64.sha256.2.2.2')
      }

      context 'with compose version v1' do
        let(:pre_condition) do
          <<-PRECOND
          class { 'dockerinstall': compose_version => '1.29.2' }
          PRECOND
        end
        it {
          is_expected.to contain_exec('docker-compose-checksum')
            .with_command('curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64.sha256 -o docker-compose-Linux-x86_64.sha256.1.29.2')
            .with_unless('grep docker-compose-Linux-x86_64 /tmp/docker-compose-Linux-x86_64.sha256.1.29.2')
        }

        it {
          is_expected.to contain_exec('docker-compose-download')
            .with_command('curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-Linux-x86_64 -o docker-compose-Linux-x86_64')
            .with_unless('sha256sum -c docker-compose-Linux-x86_64.sha256.1.29.2')
        }
      end
    end
  end
end
