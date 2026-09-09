# frozen_string_literal: true

require 'spec_helper'

describe 'dockerinstall::daemon_proxy' do
  # manage_nginx_core defaults to false, so the base case is a host whose nginx
  # is owned by another profile - the normal deployment. stream must be on, or
  # there is no conf.stream.d for any of this to land in.
  let(:pre_condition) do
    [
      'include dockerinstall',
      "class { 'nginx': stream => true }",
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

      it { is_expected.not_to contain_class('lsys_nginx') }

      context 'on a host that runs Docker and no web server' do
        let(:pre_condition) { 'include dockerinstall' }
        let(:params) { super().merge('manage_nginx_core' => true) }

        it { is_expected.to compile }

        # njs and stream are not optional extras here - the proxy cannot work
        # without either, so this class turns both on rather than leaving them
        # to be discovered when nginx fails to start.
        it {
          is_expected.to contain_class('lsys_nginx')
            .with_njs(true)
            .with_stream(true)
        }
      end

      context 'when the stream module is not enabled' do
        let(:pre_condition) do
          [
            'include dockerinstall',
            "class { 'nginx': }",
          ].join("\n")
        end

        it { is_expected.to compile.and_raise_error(%r{requires the nginx stream module}) }
      end

      # The CN has to be extracted before it can be compared, because nginx has
      # no native Common Name variable. Both maps live in stream context.
      context 'the CN extraction map' do
        it {
          is_expected.to contain_nginx__resource__map('ssl_client_s_dn_cn')
            .with_context('stream')
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
            .with_context('stream')
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

        # An empty list renders `map ... { default 0; }`, which refuses every
        # client. It fails closed, so it warns rather than fails.
        context 'with an empty allow_cn' do
          let(:params) { super().merge('allow_cn' => []) }

          it { is_expected.to compile }

          it {
            expect(catalogue.resource('nginx::resource::map', 'docker_ok')[:mappings]).to eq([])
          }
        end
      end

      context 'the njs shim' do
        it { is_expected.to contain_file('/usr/lib/nginx/njs').with_ensure('directory') }

        # The policy is deliberately NOT in the JavaScript - it reads the
        # map-derived variable, so the shim never changes when the list does.
        it {
          is_expected.to contain_file('/usr/lib/nginx/njs/dockerd_access.js')
            .with_content(%r{s\.variables\.docker_ok})
            .with_content(%r{s\.deny\(\)})
        }

        it 'keeps the allow-list out of the shim' do
          expect(catalogue.resource('file', '/usr/lib/nginx/njs/dockerd_access.js')[:content])
            .not_to match(%r{builder\.example\.com})
        end

        # js_import is only valid at stream level, so it cannot live inside the
        # server block and needs a file of its own.
        it {
          is_expected.to contain_file('/etc/nginx/conf.stream.d/00-dockerd-njs.conf')
            .with_content(%r{js_import dockerproxy from /usr/lib/nginx/njs/dockerd_access\.js;})
        }
      end

      context 'the stream server' do
        let(:host) { "#{os_facts[:networking]['fqdn']}-dockerd" }

        it {
          is_expected.to contain_nginx__resource__streamhost(host)
            .with_listen_ip('10.0.0.10')
            .with_listen_port(2376)
            .with_listen_options('ssl')
            .with_proxy('127.0.0.1:2376')
        }

        # proxy_half_close is the whole reason this is a stream server rather
        # than an http one: without it a Docker client that half-closes has its
        # return path torn down, which looks like success and delivers nothing.
        it 'sets proxy_half_close' do
          expect(catalogue.resource('nginx::resource::streamhost', host)[:raw_append])
            .to include('proxy_half_close on;')
        end

        it 'terminates mutual TLS and hands the decision to njs' do
          raw = catalogue.resource('nginx::resource::streamhost', host)[:raw_prepend]
          expect(raw).to include('ssl_verify_client on;')
          expect(raw).to include('ssl_client_certificate /etc/puppetlabs/puppet/ssl/certs/ca.pem;')
          expect(raw).to include('js_access dockerproxy.access;')
        end

        # Puppet-signed certs have no IP SANs, so verifying a loopback upstream
        # by address fails the name check and every connection fails.
        it 'overrides the upstream name that is verified' do
          expect(catalogue.resource('nginx::resource::streamhost', host)[:raw_append])
            .to include('proxy_ssl_name dockerhost.example.com;')
        end

        it 'authenticates to the daemon with a client certificate' do
          raw = catalogue.resource('nginx::resource::streamhost', host)[:raw_append]
          expect(raw).to include('proxy_ssl on;')
          expect(raw).to include('proxy_ssl_certificate /etc/docker/tls/cert.pem;')
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
          is_expected.to contain_nginx__resource__streamhost('docker.example.com-dockerd')
            .with_proxy('127.0.0.1:2375')
            .with_listen_port(2376)
        }
      end
    end
  end
end
