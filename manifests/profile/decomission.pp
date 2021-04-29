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

  class { 'dockerinstall::install':
    version              => 'absent',
    containerd_version   => 'absent',
    prerequired_packages => [],
  }
  contain dockerinstall::install

  class { 'dockerinstall::config':
    config_ensure  => 'absent',
    user_ensure    => 'absent',
    group_ensure   => 'absent',
    manage_package => false,
  }
  contain dockerinstall::config

  class { 'dockerinstall::service':
    service_ensure        => 'stopped',
    service_config_ensure => 'absent',
    service_enable        => false,
    manage_users          => false,
    manage_package        => false,
  }
  contain dockerinstall::service

  class { 'dockerinstall::compose':
    binary_ensure => 'absent',
  }

  Class['dockerinstall::service']
    -> Class['dockerinstall::config']
    -> Class['dockerinstall::install']
}
