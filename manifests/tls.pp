# Protect the Docker daemon socket with TLS certificate
#
# @summary Protect the Docker daemon socket with TLS certificate
#
# @example
#   include dockerinstall::tls
class dockerinstall::tls (
  Boolean $users_access = $dockerinstall::tls_users_access,
  Optional[String[1]] $key_group = undef,
) {
  # The two are opposite intentions about the same file: users_access opens the
  # key to every local user, key_group restricts it to root plus one group.
  # Failing here turns a silent mode surprise into a compile-time error.
  if $key_group and $users_access {
    fail(join([
          'dockerinstall::tls: key_group and users_access are mutually exclusive -',
          'users_access makes the private key world-readable, key_group restricts',
          'it to root and one group.',
    ], ' '))
  }

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

  # 0644 leaves the daemon's client key readable by every local user. Where the
  # daemon is fronted by a certificate Common Name allow-list, that allow-list is
  # only as strong as this mode: anything able to read the key can present the
  # name it carries.
  if $key_group {
    $tls_key_mode  = '0640'
    $tls_key_group = $key_group
  }
  elsif $users_access {
    $tls_key_mode  = '0644'
    $tls_key_group = undef
  }
  else {
    $tls_key_mode  = '0400'
    $tls_key_group = undef
  }

  # Client private key
  file { "${docker_tlsdir}/key.pem":
    source => "file://${hostprivkey}",
    owner  => 'root',
    group  => $tls_key_group,
    mode   => $tls_key_mode,
  }
}
