# @summary Docker basic setup
#
# Docker basic setup
#
# @param docker_dir_ensure
#   Ensure parameter to File esource for /etc/docker directory
#   Could be 'directory' or 'absent'
#
# @param users_access
#   Whether other system users can access Docker TLS directory
#
# @param manage_docker_certdir
#
# @param manage_docker_tlsdir
#
# @example
#   include dockerinstall::setup
class dockerinstall::setup (
  Boolean $manage_docker_certdir = $dockerinstall::manage_docker_certdir,
  Boolean $manage_docker_tlsdir = $dockerinstall::manage_docker_tlsdir,
  Boolean $users_access = $dockerinstall::tls_users_access,
  Enum['directory', 'absent'] $docker_dir_ensure = $dockerinstall::docker_dir_ensure,
) {
  include dockerinstall::params

  $docker_dir = $dockerinstall::params::docker_dir
  $docker_certdir = $dockerinstall::params::docker_certdir
  $docker_tlsdir = $dockerinstall::params::docker_tlsdir

  if $facts['os']['family'] == 'windows' {
    if $facts['identity']['privileged'] {
      file { [$docker_dir, "${docker_dir}\\config"]:
        ensure => $docker_dir_ensure,
      }

      if $manage_docker_certdir or $manage_docker_tlsdir {
        file { $docker_certdir:
          ensure => directory,
        }
      }
    }
  }
  else {
    if $facts['identity']['user'] == 'root' {
      file { $docker_dir:
        ensure  => $docker_dir_ensure,
        recurse => true,
        force   => true,
      }

      if $manage_docker_certdir {
        file { $docker_certdir:
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
}
