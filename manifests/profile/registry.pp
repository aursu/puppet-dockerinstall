# @summary Docker registry installation profile
#
# Docker registry installation profile
#
# @param server_name
#   Virtual host name the registry is served under.
#
# @param cert_identity
#   Certificate to look up for the vhost. Defaults to `server_name`; set it to a
#   wildcard identity where one certificate covers several names.
#
# @param ssl_client_ca_auth
#   Whether registry clients must present a client certificate (mutual TLS).
#
# @param ssl_client_ca_certs
#   Hostnames whose certificates are accepted as client CAs.
#
# @param manage_cert_data
#   Whether this class deploys the certificate and key, or expects them present.
#
# @param ssl_cert
#   Explicit path to the server certificate, bypassing the lookup.
#
# @param ssl_key
#   Explicit path to the server private key, bypassing the lookup.
#
# @param manage_nginx_core
#   Whether this class manages nginx itself. Set false where another profile on
#   the host already owns nginx core.
#
# @param manage_web_user
#   Whether to manage the web server user and group.
#
# @param global_ssl_redirect
#   Whether to redirect plain HTTP to HTTPS for the main vhost.
#
# @param api_listen_ip
#   Address for a second vhost serving the registry API over TLS, for consumers
#   that cannot use the main vhost. `undef` (default) creates nothing.
#
#   The main vhost is built for docker clients: it can require mutual TLS and it
#   gates `/v2/*` behind the registry auth-token map. A client that speaks the
#   registry API directly with its own bearer token — GitLab's registry
#   integration is the usual one — satisfies neither, which is why such setups
#   traditionally reach the container's published port over plain HTTP. This
#   vhost replaces that with TLS terminated by nginx and an explicit allow-list,
#   proxying to the registry on loopback.
#
#   Must be a specific address, never `0.0.0.0`: where
#   `dockerinstall::registry::base::listen_ip` is `127.0.0.1`, a wildcard bind on
#   the same port collides with the container's own publication.
#
# @param api_allow
#   Source addresses permitted to reach `api_listen_ip`. Everything else is
#   denied. Empty (default) with `api_listen_ip` set would deny everyone, which
#   is safe but pointless — set both or neither.
#
# @param api_port
#   Port for that vhost. Default 5000, matching the registry's own port so
#   existing consumers need only change scheme and not address.
#
# @example
#   include dockerinstall::profile::registry
#
# @example Registry on loopback, API exposed over TLS to one host
#   class { 'dockerinstall::registry::base':
#     listen_ip => '127.0.0.1',
#   }
#   class { 'dockerinstall::profile::registry':
#     server_name   => 'registry.example.com',
#     api_listen_ip => '10.0.0.10',
#     api_allow     => ['10.0.0.16'],
#   }
class dockerinstall::profile::registry (
  String $server_name,
  Optional[Stdlib::IP::Address] $api_listen_ip = undef,
  Array[Stdlib::IP::Address] $api_allow = [],
  Stdlib::Port $api_port = 5000,
  Optional[String] $cert_identity = $server_name,
  Boolean $ssl_client_ca_auth = true,
  Optional[Array[Stdlib::Fqdn]] $ssl_client_ca_certs = undef,
  Boolean $manage_cert_data = true,
  # TLS data
  Optional[String] $ssl_cert = undef,
  Optional[String] $ssl_key = undef,
  # WEB service
  Boolean $manage_nginx_core = true,
  Boolean $manage_web_user = true,
  Boolean $global_ssl_redirect = true,
) {
  include tlsinfo
  include dockerinstall::registry::base

  include puppet::globals
  $localcacert = $puppet::globals::localcacert

  include dockerinstall::registry::params
  $internal_certdir = $dockerinstall::registry::params::internal_certdir
  $internal_cacert  = $dockerinstall::registry::params::internal_cacert

  if $ssl_client_ca_auth {
    # CA certificate
    # create CA certificate directory
    file { $internal_certdir:
      ensure => directory,
    }

    if $ssl_client_ca_certs {
      $cacertdata = $ssl_client_ca_certs.map |$ca_name| { tlsinfo::lookup($ca_name) }

      file { $internal_cacert:
        ensure  => file,
        content => $cacertdata.join("\n"),
      }
    }
    else {
      file { $internal_cacert:
        ensure => file,
        source => "file://${localcacert}",
      }
    }

    if $manage_nginx_core {
      File[$internal_cacert] ~> Class['nginx::service']
    }
  }

  # if both SSL cert and key provided via parameters - them have more priority
  # then certificate identity for lookup
  if $ssl_cert and $ssl_key {
    $cert_lookupkey = $server_name
    $certdata       = $ssl_cert

    if $manage_cert_data {
      # we use Hiera for certificate/private key storage
      tlsinfo::certpair { $server_name:
        identity => true,
        cert     => $ssl_cert,
        pkey     => $ssl_key,
        # in case of self signed CA
        strict   => false,
      }
    }
  }
  else {
    $cert_lookupkey = $cert_identity
    $certdata       = tlsinfo::lookup($cert_lookupkey)

    if $manage_cert_data {
      # we use Hiera for certificate/private key storage
      tlsinfo::certpair { $cert_identity:
        identity => true,
        # in case of self signed CA
        strict   => false,
      }
    }
  }

  # we use default locations for certificate and key storage - get
  # these locations
  $ssl_cert_path = tlsinfo::certpath($certdata)
  $ssl_key_path = tlsinfo::keypath($certdata)

  class { 'dockerinstall::registry::nginx':
    server_name         => $server_name,
    manage_nginx_core   => $manage_nginx_core,
    manage_web_user     => $manage_web_user,
    ssl                 => true,
    ssl_cert            => $ssl_cert_path,
    ssl_key             => $ssl_key_path,
    ssl_client_ca_auth  => $ssl_client_ca_auth,
    global_ssl_redirect => $global_ssl_redirect,
  }

  # Second vhost: the registry API over TLS, for consumers the main vhost cannot
  # serve. See the api_listen_ip documentation for why one is sometimes needed.
  #
  # `use_default_location` is REQUIRED and is not the module default. Without
  # it nginx::resource::server renders a bare TLS listener with no location at
  # all — no proxy_pass, and no allow/deny either, so the access restriction
  # silently does not exist while nginx starts happily and answers 404. Verified
  # the hard way on 2026-09-09.
  #
  # `listen_port` equal to `ssl_port` is what makes the vhost SSL-only:
  # nginx::resource::server computes `ssl_only` from that equality rather than
  # taking a flag, so anything else leaves a plain-HTTP listener on the port.
  if $api_listen_ip {
    nginx::resource::server { "${server_name}-api":
      server_name          => [$server_name],
      listen_ip            => $api_listen_ip,
      listen_port          => $api_port,
      ssl                  => true,
      ssl_port             => $api_port,
      ssl_cert             => $ssl_cert_path,
      ssl_key              => $ssl_key_path,
      ssl_verify_client    => 'off',
      ipv6_enable          => false,
      # Always 5000: that is the port the registry container publishes, whatever
      # address it binds. api_port is the port nginx LISTENS on, which is a
      # separate thing that merely defaults to the same number.
      proxy                => 'http://127.0.0.1:5000',
      location_allow       => $api_allow,
      location_deny        => ['all'],
      use_default_location => true,
    }
  }

  if $manage_nginx_core and $manage_cert_data {
    Tlsinfo::Certpair[$cert_lookupkey] ~> Class['nginx::service']
  }
}
