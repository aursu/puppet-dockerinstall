# @summary Setup client cert auth for registry
#
# Setup client cert auth for registry usung Puppet CA certificates
#
# @param server_name
#   Docker registry server name
#
# @param server_port
#   Docker registry server port
#
# @example
#   dockerinstall::registry::clientauth { 'namevar': }
define dockerinstall::registry::clientauth (
  Stdlib::Fqdn $server_name = $name,
  Optional[Stdlib::Port] $server_port = undef,
) {
  include dockerinstall::params

  $localcacert = $dockerinstall::params::localcacert
  $hostcert    = $dockerinstall::params::hostcert
  $hostprivkey = $dockerinstall::params::hostprivkey
  $docker_certdir = $dockerinstall::params::docker_certdir

  # https://docs.docker.com/engine/security/certificates/
  # /etc/docker/certs.d/
  # +-- my-https.registry.example.com          <-- Hostname without port
  #    |-- client.cert                         <-- .cert suffix is mandatory
  #    |-- client.key                          <-- .key seffix is mandatory and name w/o suffix
  #    |                                            must match to name w/o .cert suffix
  #    +-- ca.crt                              <-- .crt suffix is mandatory
  if $server_port {
    if $facts['os']['family'] == 'windows' {
      $auth_certdir = "${docker_certdir}/${server_name}${server_port}"
    }
    else {
      $auth_certdir = "${docker_certdir}/${server_name}:${server_port}"
    }
  }
  else {
    $auth_certdir = "${docker_certdir}/${server_name}"
  }

  file { $auth_certdir:
    ensure => directory,
  }

  # CA certificate
  file { "${auth_certdir}/ca.crt":
    source => "file://${localcacert}",
  }

  # Client certificate
  file { "${auth_certdir}/client.cert":
    source => "file://${hostcert}",
  }

  # Client private key
  file { "${auth_certdir}/client.key":
    source => "file://${hostprivkey}",
  }
}
