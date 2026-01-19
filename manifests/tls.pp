# Protect the Docker daemon socket with TLS certificate
#
# @summary Protect the Docker daemon socket with TLS certificate
#
# @example
#   include dockerinstall::tls
class dockerinstall::tls (
  Boolean $users_access = $dockerinstall::tls_users_access,
) {
  include dockerinstall::params

  $localcacert = $dockerinstall::params::localcacert
  $hostcert    = $dockerinstall::params::hostcert
  $hostprivkey = $dockerinstall::params::hostprivkey
  $docker_tlsdir = $dockerinstall::params::docker_tlsdir

  # --tlscacert string                      Trust certs signed only by this CA (default "~/.docker/ca.pem")
  # --tlscert string                        Path to TLS certificate file (default "~/.docker/cert.pem")
  # --tlskey string                         Path to TLS key file (default ~/.docker/key.pem")

  # /etc/docker/tls/
  #    ├── cert.pem
  #    ├── key.pem
  #    └── ca.pem

  # CA certificate
  file { "${docker_tlsdir}/ca.pem":
    source => "file://${localcacert}",
  }

  # Client certificate
  file { "${docker_tlsdir}/cert.pem":
    source => "file://${hostcert}",
  }

  if $users_access {
    $tls_key_mode = '0644'
  }
  else {
    $tls_key_mode = '0400'
  }

  # Client private key
  file { "${docker_tlsdir}/key.pem":
    source => "file://${hostprivkey}",
    owner  => 'root',
    mode   => $tls_key_mode,
  }
}
