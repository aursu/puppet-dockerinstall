# @summary Docker basic setup
#
# Docker basic setup
#
# @param docker_dir_ensure
#   Ensure parameter to File esource for /etc/docker directory
#   Could be 'directory' or 'absent'
#
# @param docker_tlsdir
#   Docker TLS directory. Default is /etc/docker/tls
#
# @param users_access
#   Whether other system users can access Docker TLS directory
#
# @example
#   include dockerinstall::setup
class dockerinstall::setup (
  Boolean $manage_docker_certdir = $dockerinstall::manage_docker_certdir,
  Boolean $manage_docker_tlsdir = $dockerinstall::manage_docker_tlsdir,
  Stdlib::Unixpath $docker_tlsdir = $dockerinstall::params::docker_tlsdir,
  Boolean $users_access = $dockerinstall::tls_users_access,
  Enum['directory', 'absent'] $docker_dir_ensure = $dockerinstall::docker_dir_ensure,
) inherits dockerinstall::params {
  if $facts['identity']['user'] == 'root' {
    file { '/etc/docker':
      ensure  => $docker_dir_ensure,
      recurse => true,
      force   => true,
    }

    if $manage_docker_certdir {
      file { '/etc/docker/certs.d':
        ensure => directory,
        owner  => 'root',
        mode   => '0700',
      }
    }

    if $users_access {
      $docker_tlsdir_mode = '0711'
    }
    else {
      $docker_tlsdir_mode = '0700'
    }

    if $manage_docker_tlsdir {
      file { $docker_tlsdir:
        ensure => directory,
        owner  => 'root',
        mode   => $docker_tlsdir_mode,
      }
    }
  }
}
