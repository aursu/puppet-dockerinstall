# frozen_string_literal: true

require 'spec_helper'

describe 'dockerinstall::daemon_proxy' do
  # manage_nginx_core defaults to false, so the base case is a host whose nginx
  # is owned by another profile - which is the normal deployment.
  let(:pre_condition) do
    [
      'include dockerinstall',
      "class { 'nginx': }",
    ].join("\n")
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'listen_ip' => '10.0.0.10',
          'allow_cn' => ['builder.example.com'],
          'ssl_cert' => '/etc/docker/tls/cert.pem',
          'ssl_key' => '/etc/docker/tls/key.pem',
          'ssl_client_ca' => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
          'ssl_ca' => '/etc/docker/tls/ca.pem',
          'proxy_ssl_name' => 'dockerhost.example.com',
        }
      end

      it { is_expected.to compile }

      # The default: another profile owns nginx core, so this class must not
      # declare it.
      it { is_expected.not_to contain_class('lsys_nginx') }

      context 'on a host that runs Docker and no web server' do
        let(:pre_condition) { 'include dockerinstall' }
        let(:params) { super().merge('manage_nginx_core' => true) }

        it { is_expected.to compile }
        it { is_expected.to contain_class('lsys_nginx') }
      end

      # The CN has to be extracted before it can be compared, because nginx has
      # no native Common Name variable.
      context 'the CN extraction map' do
        it {
          is_expected.to contain_nginx__resource__map('ssl_client_s_dn_cn')
            .with_string('$ssl_client_s_dn')
            .with_default('""')
        }

        # This is a security assertion, not a formatting one. Unanchored, `CN=`
        # matches anywhere in the DN - including inside another attribute's
        # VALUE - and nginx captures the first match, so a certificate carrying
        # `OU=xCN=builder.example.com,CN=attacker` would yield the allow-listed
        # name and pass. Do not relax this expectation.
        it 'anchors CN= to the start of the DN or a comma' do
          expect(catalogue.resource('nginx::resource::map', 'ssl_client_s_dn_cn')[:mappings])
            .to eq([{ 'key' => '~(^|,)CN=(?<CN>[^,]+)', 'value' => '$CN' }])
        end
      end

      context 'the allow-list map' do
        it {
          is_expected.to contain_nginx__resource__map('docker_ok')
            .with_string('$ssl_client_s_dn_cn')
            .with_default('0')
        }

        it 'quotes each permitted CN and maps it to 1' do
          expect(catalogue.resource('nginx::resource::map', 'docker_ok')[:mappings])
            .to eq([{ 'key' => '"builder.example.com"', 'value' => '1' }])
        end

        context 'with several CNs' do
          let(:params) { super().merge('allow_cn' => ['a.example.com', 'b.example.com']) }

          it {
            expect(catalogue.resource('nginx::resource::map', 'docker_ok')[:mappings])
              .to eq([
                       { 'key' => '"a.example.com"', 'value' => '1' },
                       { 'key' => '"b.example.com"', 'value' => '1' },
                     ])
          }
        end

        # An empty list renders `map ... { default 0; }`, which is valid nginx
        # and refuses everyone. It fails closed, so it warns rather than fails.
        context 'with an empty allow_cn' do
          let(:params) { super().merge('allow_cn' => []) }

          it { is_expected.to compile }

          it {
            expect(catalogue.resource('nginx::resource::map', 'docker_ok')[:mappings]).to eq([])
          }
        end
      end

      # The $connection_upgrade map is depended on, never declared here: both
      # aursu/nginx and aursu/gitlabinstall already render it, and a second copy
      # stops nginx from starting.
      it { is_expected.not_to contain_nginx__resource__map('connection_upgrade') }

      context 'when nginx::proxy_connection_upgrade is disabled elsewhere' do
        let(:pre_condition) do
          [
            'include dockerinstall',
            "class { 'nginx': proxy_connection_upgrade => false }",
          ].join("\n")
        end

        it {
          is_expected.to compile.and_raise_error(%r{requires the .connection_upgrade map})
        }
      end

      context 'the vhost' do
        let(:vhost) { "#{os_facts[:networking]['fqdn']}-dockerd" }

        it {
          is_expected.to contain_nginx__resource__server(vhost)
            .with_listen_ip('10.0.0.10')
            .with_listen_port(2376)
            .with_ssl_port(2376)
            .with_ssl_verify_client('on')
            .with_proxy('https://127.0.0.1:2376')
            .with_proxy_http_version('1.1')
            .with_use_default_location(true)
        }

        # Without use_default_location the vhost renders with no location block
        # at all - no proxy_pass and no CN check - and nginx answers 404 happily.
        it 'refuses the request when the CN is not allow-listed' do
          expect(catalogue.resource('nginx::resource::server', vhost)[:location_raw_prepend])
            .to eq(['if ($docker_ok = 0) { return 403; }'])
        end

        # Docker hijacks the connection for exec and attach, so these must be
        # present or every CI job fails while `docker version` keeps working.
        it 'passes the upgrade headers through' do
          raw = catalogue.resource('nginx::resource::server', vhost)[:location_raw_append]
          expect(raw).to include('proxy_set_header Upgrade $http_upgrade;')
          expect(raw).to include('proxy_set_header Connection $connection_upgrade;')
        end

        # Puppet-signed certs have no IP SANs, so verifying a loopback upstream
        # by address fails the name check and every request 502s.
        it 'overrides the upstream name that is verified' do
          expect(catalogue.resource('nginx::resource::server', vhost)[:location_raw_append])
            .to include('proxy_ssl_name dockerhost.example.com;')
        end

        it 'authenticates to the daemon with a client certificate' do
          raw = catalogue.resource('nginx::resource::server', vhost)[:location_raw_append]
          expect(raw).to include('proxy_ssl_certificate /etc/docker/tls/cert.pem;')
          expect(raw).to include('proxy_ssl_certificate_key /etc/docker/tls/key.pem;')
          expect(raw).to include('proxy_ssl_trusted_certificate /etc/docker/tls/ca.pem;')
        end
      end

      context 'with an explicit server_name and a separate upstream port' do
        let(:params) do
          super().merge(
            'server_name' => 'docker.example.com',
            'port' => 2376,
            'upstream_port' => 2375,
          )
        end

        it {
          is_expected.to contain_nginx__resource__server('docker.example.com-dockerd')
            .with_proxy('https://127.0.0.1:2375')
            .with_listen_port(2376)
        }
      end
    end
  end
end
