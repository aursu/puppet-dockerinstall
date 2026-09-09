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

      context 'with a group granted read access to the key' do
        let(:params) do
          {
            tls_key_group: 'www-data',
          }
        end

        it {
          is_expected.to contain_file('/etc/docker/tls/key.pem')
            .with_mode('0640')
            .with_group('www-data')
        }
      end

      # The bind was hardcoded to the wildcard before 0.33.0.
      context 'with the API bound to loopback' do
        let(:params) do
          {
            tls_enable: true,
            tls_listen_ip: '127.0.0.1',
          }
        end

        it { is_expected.to compile }
        it { is_expected.to contain_class('dockerinstall::service').with_tcp_bind(['tcp://127.0.0.1:2376']) }
      end

      context 'with no tls_listen_ip' do
        let(:params) { { tls_enable: true } }

        it { is_expected.to contain_class('dockerinstall::service').with_tcp_bind(['tcp://0.0.0.0:2376']) }
      end

      context 'with the API proxy composed in' do
        # Pinned because the proxy derives proxy_ssl_name from the node certname,
        # and the default node name in this harness is the container hostname.
        let(:node) { 'dockerhost.example.com' }
        let(:pre_condition) { "class { 'nginx': }" }
        let(:params) do
          {
            tls_enable: true,
            tls_listen_ip: '127.0.0.1',
            tls_key_group: 'www-data',
            proxy_enable: true,
            proxy_listen_ip: '10.0.0.10',
            proxy_allow_cn: ['builder.example.com'],
          }
        end

        it { is_expected.to compile }

        # The point of composing it here: the proxy's upstream is the daemon's
        # own listen address by construction, so the two cannot drift apart.
        it {
          is_expected.to contain_class('dockerinstall::daemon_proxy')
            .with_upstream_host('127.0.0.1')
            .with_listen_ip('10.0.0.10')
            .with_allow_cn(['builder.example.com'])
            .with_ssl_cert('/etc/docker/tls/cert.pem')
            .with_ssl_key('/etc/docker/tls/key.pem')
            .with_ssl_ca('/etc/docker/tls/ca.pem')
        }

        it 'verifies the upstream against the node certname, not the address' do
          expect(catalogue.resource('class', 'dockerinstall::daemon_proxy')[:proxy_ssl_name])
            .to eq('dockerhost.example.com')
        end
      end

      context 'with the proxy enabled but TLS off' do
        let(:params) do
          {
            tls_enable: false,
            proxy_enable: true,
            proxy_allow_cn: ['builder.example.com'],
          }
        end

        it { is_expected.to compile.and_raise_error(%r{proxy_enable requires tls_enable}) }
      end

      context 'without the proxy' do
        it { is_expected.not_to contain_class('dockerinstall::daemon_proxy') }
      end
    end
  end
end
