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

        # stream is not an optional extra - none of this renders without
        # conf.stream.d - so this class turns it on rather than leaving it to be
        # discovered when the configuration silently does nothing.
        it { is_expected.to contain_class('lsys_nginx').with_stream(true) }
      end

      # Regression guard for the ordering bug that broke ci2's catalogue: this
      # class used to build the path from $nginx::conf_dir, which is unreadable
      # when the profile owning nginx is evaluated after this one. It cannot be
      # reproduced directly - rspec-puppet's pre_condition always runs first, so
      # nginx is never "declared later" here. What this does catch is a
      # reintroduction of that read: sourcing the path from $nginx::conf_dir
      # again would ignore the parameter and put the file back under /etc/nginx.
      context 'with a non-default stream_conf_dir' do
        let(:params) { super().merge('stream_conf_dir' => '/opt/nginx/conf.stream.d') }

        it {
          is_expected.to contain_file('/opt/nginx/conf.stream.d/00-dockerd-njs.conf')
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

      # The allow-list decides which upstream proxy_pass targets, because the
      # stream module has no conditional at content phase. Allow-listed names get
      # the daemon; everything else gets the refusal listener.
      context 'the upstream map' do
        it {
          is_expected.to contain_nginx__resource__map('docker_backend')
            .with_context('stream')
            .with_string('$ssl_client_s_dn_cn')
            .with_default('127.0.0.1:12376')
        }

        it 'points each permitted CN at the daemon' do
          expect(catalogue.resource('nginx::resource::map', 'docker_backend')[:mappings])
            .to eq([{ 'key' => '"builder.example.com"', 'value' => '127.0.0.1:2376' }])
        end

        context 'with several CNs' do
          let(:params) { super().merge('allow_cn' => ['a.example.com', 'b.example.com']) }

          it {
            expect(catalogue.resource('nginx::resource::map', 'docker_backend')[:mappings])
              .to eq([
                       { 'key' => '"a.example.com"', 'value' => '127.0.0.1:2376' },
                       { 'key' => '"b.example.com"', 'value' => '127.0.0.1:2376' },
                     ])
          }
        end

        # An empty list leaves only the default, so every client reaches the
        # refusal listener. It fails closed, so it warns rather than fails.
        context 'with an empty allow_cn' do
          let(:params) { super().merge('allow_cn' => []) }

          it { is_expected.to compile }

          it {
            expect(catalogue.resource('nginx::resource::map', 'docker_backend')[:mappings]).to eq([])
          }
        end

        context 'with a non-default refusal listener' do
          let(:params) { super().merge('deny_listen_ip' => '127.0.0.2', 'deny_port' => 9999) }

          it {
            is_expected.to contain_nginx__resource__map('docker_backend')
              .with_default('127.0.0.2:9999')
          }
        end
      end

      context 'the refusal listener' do
        # A real listener that answers and closes, rather than an address nothing
        # happens to be bound to: a closed port refuses by accident of absence,
        # logs at ERROR level indistinguishably from the daemon being down, and
        # silently becomes a proxy to whatever binds it next.
        it {
          is_expected.to contain_file('/etc/nginx/conf.stream.d/00-dockerd-deny.conf')
            .with_content(%r{listen 127\.0\.0\.1:12376;})
            .with_content(%r{return "";})
        }

        # 0.36.2 and earlier shipped an njs shim. Removing a resource from a
        # manifest orphans the file, so these are declared absent for one release.
        it { is_expected.to contain_file('/usr/lib/nginx/njs/dockerd_access.js').with_ensure('absent') }
        it { is_expected.to contain_file('/etc/nginx/conf.stream.d/00-dockerd-njs.conf').with_ensure('absent') }
      end

      context 'the stream server' do
        let(:host) { "#{os_facts[:networking]['fqdn']}-dockerd" }

        it {
          is_expected.to contain_nginx__resource__streamhost(host)
            .with_listen_ip('10.0.0.10')
            .with_listen_port(2376)
            .with_listen_options('ssl')
            .with_proxy('$docker_backend')
        }

        # proxy_half_close is the whole reason this is a stream server rather
        # than an http one: without it a Docker client that half-closes has its
        # return path torn down, which looks like success and delivers nothing.
        it 'sets proxy_half_close' do
          expect(catalogue.resource('nginx::resource::streamhost', host)[:raw_append])
            .to include('proxy_half_close on;')
        end

        # njs was tried and does not work here: js_access runs before the TLS
        # handshake, so $ssl_client_s_dn is empty and every client is refused.
        it 'terminates mutual TLS and decides by upstream, not by njs' do
          raw = catalogue.resource('nginx::resource::streamhost', host)[:raw_prepend]
          expect(raw).to include('ssl_verify_client on;')
          expect(raw).to include('ssl_client_certificate /etc/puppetlabs/puppet/ssl/certs/ca.pem;')
          expect(raw.join).not_to match(%r{js_access})
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

        it 'points the allow-listed CN at the separate upstream port' do
          expect(catalogue.resource('nginx::resource::map', 'docker_backend')[:mappings])
            .to eq([{ 'key' => '"builder.example.com"', 'value' => '127.0.0.1:2375' }])
        end

        it {
          is_expected.to contain_nginx__resource__streamhost('docker.example.com-dockerd')
            .with_listen_port(2376)
        }
      end
    end
  end
end
