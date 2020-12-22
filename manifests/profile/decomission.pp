# @summary Docker daemon decomission
#
# Docker daemon decomission
#
# @example
#   include dockerinstall::profile::decomission
class dockerinstall::profile::decomission {
  include dockerinstall

  class { 'dockerinstall::repos':
    repo_ensure => 'absent',
  }

  class { 'dockerinstall::setup':
    docker_dir_ensure     => 'absent',
    manage_docker_tlsdir  => false,
    manage_docker_certdir => false,
  }

  class { 'dockerinstall::install':
    version              => 'absent',
    prerequired_packages => [],
  }

  class { 'dockerinstall::config':
    config_ensure  => 'absent',
    user_ensure    => 'absent',
    group_ensure   => 'absent',
    manage_package => false,
  }

  class { 'dockerinstall::service':
    service_ensure        => 'stopped',
    service_config_ensure => 'absent',
    service_enable        => false,
    manage_users          => false,
    manage_package        => false,
  }

  class { 'dockerinstall::compose':
    binary_ensure => 'absent',
  }

  Class['dockerinstall::service']
    -> Class['dockerinstall::config']
    -> Class['dockerinstall::install']
}
