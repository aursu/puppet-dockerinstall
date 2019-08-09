# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include dockerinstall::tls
class dockerinstall::tls (
    Stdlib::Unixpath
            $docker_tlsdir = $dockerinstall::docker_tlsdir,
)
{
  include dockerinstall::params

  $localcacert = $dockerinstall::params::localcacert
  $hostcert    = $dockerinstall::params::hostcert
  $hostprivkey = $dockerinstall::params::hostprivkey

  # --tlscacert string                      Trust certs signed only by this CA (default "~/.docker/ca.pem")
  # --tlscert string                        Path to TLS certificate file (default "~/.docker/cert.pem")
  # --tlskey string                         Path to TLS key file (default ~/.docker/key.pem")

  # /etc/docker/tls/
  #    ├── cert.pem
  #    ├── key.pem
  #    └── ca.pem

  # CA certificate
  file { "${docker_tlsdir}/ca.pem":
      source  => "file://${localcacert}",
  }

  # Client certificate
  file { "${docker_tlsdir}/cert.pem":
      source  => "file://${hostcert}",
  }

  # Client private key
  file { "${docker_tlsdir}/key.pem":
      source => "file://${hostprivkey}",
      owner  => 'root',
      mode   => '0400',
  }
}
