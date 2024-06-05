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
# @param manage_user_dir
#
# @example
#   dockerinstall::registry::clientauth { 'namevar': }
define dockerinstall::registry::clientauth (
  Stdlib::Fqdn $server_name = $name,
  Boolean $manage_user_dir = true,
  Optional[Stdlib::Port] $server_port = undef,
) {
  include dockerinstall::params
  include dockerinstall::globals

  $localcacert = $dockerinstall::params::localcacert
  $hostcert    = $dockerinstall::params::hostcert
  $hostprivkey = $dockerinstall::params::hostprivkey
  $docker_certdir = $dockerinstall::params::docker_certdir
  $docker_user_dir = $dockerinstall::globals::docker_user_dir
  $docker_user_certdir = $dockerinstall::globals::docker_user_certdir

  # https://docs.docker.com/engine/security/certificates/
  # /etc/docker/certs.d/
  # +-- my-https.registry.example.com          <-- Hostname without port
  #    |-- client.cert                         <-- .cert suffix is mandatory
  #    |-- client.key                          <-- .key seffix is mandatory and name w/o suffix
  #    |                                            must match to name w/o .cert suffix
  #    +-- ca.crt                              <-- .crt suffix is mandatory
  if $server_port {
    if $facts['os']['family'] == 'windows' {
      $auth_certdir = "${docker_certdir}\\${server_name}${server_port}"
      $user_auth_certdir = "${docker_user_certdir}\\${server_name}${server_port}"
    }
    else {
      $auth_certdir = "${docker_certdir}/${server_name}:${server_port}"
      $user_auth_certdir = "${docker_user_certdir}/${server_name}:${server_port}"
    }
  }
  else {
    if $facts['os']['family'] == 'windows' {
      $auth_certdir = "${docker_certdir}\\${server_name}"
      $user_auth_certdir = "${docker_user_certdir}\\${server_name}"
    }
    else {
      $auth_certdir = "${docker_certdir}/${server_name}"
      $user_auth_certdir = "${docker_user_certdir}/${server_name}"
    }
  }

  file { $auth_certdir:
    ensure => directory,
  }

  if $manage_user_dir and $docker_user_dir {
    file { $user_auth_certdir:
      ensure => directory,
    }
  }

  if $facts['os']['family'] == 'windows' {
    # CA certificate
    file { "${auth_certdir}\\ca.crt":
      source => $localcacert,
    }

    # Client certificate
    file { "${auth_certdir}\\client.cert":
      source => $hostcert,
    }

    # Client private key
    file { "${auth_certdir}\\client.key":
      source => $hostprivkey,
    }

    if $manage_user_dir and $docker_user_dir {
      file { "${user_auth_certdir}\\ca.crt":
        source => $localcacert,
      }

      # Client certificate
      file { "${user_auth_certdir}\\client.cert":
        source => $hostcert,
      }

      # Client private key
      file { "${user_auth_certdir}\\client.key":
        source => $hostprivkey,
      }
    }
  }
  else {
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

    if $manage_user_dir and $docker_user_dir {
      # CA certificate
      file { "${user_auth_certdir}/ca.crt":
        source => "file://${localcacert}",
      }

      # Client certificate
      file { "${user_auth_certdir}/client.cert":
        source => "file://${hostcert}",
      }

      # Client private key
      file { "${user_auth_certdir}/client.key":
        source => "file://${hostprivkey}",
      }
    }
  }
}
