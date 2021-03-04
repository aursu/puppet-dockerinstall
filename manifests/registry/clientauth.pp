# @summary Setup client cert auth for registry
#
# Setup client cert auth for registry usung Puppet CA certificates
#
# @example
#   dockerinstall::registry::clientauth { 'namevar': }
define dockerinstall::registry::clientauth (
  Stdlib::Fqdn
          $server_name = $name,
  Optional[Stdlib::Port]
          $server_port = undef,
)
{
  include dockerinstall::params

  $localcacert = $dockerinstall::params::localcacert
  $hostcert    = $dockerinstall::params::hostcert
  $hostprivkey = $dockerinstall::params::hostprivkey

  # https://docs.docker.com/engine/security/certificates/
  # /etc/docker/certs.d/
  # +-- my-https.registry.example.com          <-- Hostname without port
  #    |-- client.cert
  #    |-- client.key
  #    +-- ca.crt
  if $server_port {
    $auth_certdir = "/etc/docker/certs.d/${server_name}:${server_port}"
  }
  else {
    $auth_certdir = "/etc/docker/certs.d/${server_name}"
  }

  file { $auth_certdir:
    ensure => directory,
  }

  # CA certificate
  file { "${auth_certdir}/ca.crt":
      source  => "file://${localcacert}",
  }

  # Client certificate
  file { "${auth_certdir}/client.cert":
      source  => "file://${hostcert}",
  }

  # Client private key
  file { "${auth_certdir}/client.key":
      source  => "file://${hostprivkey}",
  }
}
