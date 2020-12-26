# @summary Docker registry installation profile
#
# Docker registry installation profile
#
# @example
#   include dockerinstall::registry
class dockerinstall::profile::registry (
  String  $server_name,
  Optional[String]
          $cert_identity          = $server_name,
  Boolean $ssl_client_ca_auth     = true,
  Optional[Array[Stdlib::Fqdn]]
          $ssl_client_ca_certs    = undef,
  Boolean $manage_cert_data       = true,
  # TLS data
  Optional[String]
          $ssl_cert               = undef,
  Optional[String]
          $ssl_key                = undef,
  # WEB service
  Boolean $manage_nginx_core      = true,
  Boolean $manage_web_user        = true,
  Boolean $global_ssl_redirect    = true,
)
{
  include tlsinfo
  include dockerinstall::registry::base

  include puppet::params
  $localcacert = $puppet::params::localcacert

  include dockerinstall::registry::params
  $internal_certdir = $dockerinstall::registry::params::internal_certdir
  $internal_cacert  = $dockerinstall::registry::params::internal_cacert

  if $ssl_client_ca_auth {
    # CA certificate
    # create CA certificate directory
    file { $internal_certdir:
      ensure  => directory,
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

  if $manage_nginx_core and $manage_cert_data {
    Tlsinfo::Certpair[$cert_lookupkey] ~> Class['nginx::service']
  }
}
