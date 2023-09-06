# @summary Docker config setup (daemon.json)
#
# Docker config setup (daemon.json)
#
# @param selinux
#   Whether to enable selinux support
#
# @example
#   include dockerinstall::config
class dockerinstall::config (
    Boolean $manage_users      = $dockerinstall::manage_os_users,
    Dockerinstall::UserList
            $docker_users      = $dockerinstall::docker_users,
    String  $group             = $dockerinstall::docker_group,
    Boolean $manage_package    = $dockerinstall::manage_package,
    # https://github.com/puppetlabs/puppetlabs-stdlib#stdlibipaddressv4cidr
    Optional[Stdlib::IP::Address::V4::CIDR]
            $bip               = undef,
    Optional[Integer]
            $mtu               = undef,
    Optional[Boolean]
            $selinux           = undef,
    Optional[Dockerinstall::StorageDriver]
            $storage_driver    = undef,
    Optional[
      Array[Dockerinstall::StorageOptions]
    ]       $storage_opts      = undef,
    Optional[Dockerinstall::CgroupDriver]
            $cgroup_driver     = undef,
    Optional[Dockerinstall::LogDriver]
            $log_driver        = undef,
    Optional[Dockerinstall::Log::JSONFile]
            $log_opts          = undef,
    String  $user_ensure       = 'present',
    String  $group_ensure      = 'present',
    String  $config_ensure     = 'file',
    Boolean $system_user       = true,
    Boolean $system_group      = true,
) {
    include dockerinstall::install

    if $manage_users {
        group { 'docker':
            ensure => $group_ensure,
            name   => $group,
            system => $system_group,
        }

        $docker_users_list = $docker_users ? {
          Array   => $docker_users,
          default => [$docker_users]
        }
        $users = $docker_users_list - ['docker']

        user {
            default:
              ensure     => $user_ensure,
              groups     => [$group],
              membership => 'minimum',
            ;
            $users:
              tag => 'docker',
            ;
            'docker':
              system => $system_user,
            ;
        }

        if $user_ensure == 'present' {
          Class['dockerinstall::install']
            -> Group['docker']
            -> User['docker']
        }
        else {
          User['docker'] -> Group['docker']
        }
    }

    # TLS
    # https://docs.docker.com/engine/security/https/

    if $cgroup_driver {
      $exec_opts = ["native.cgroupdriver=${cgroup_driver}"]
    }
    else {
      $exec_opts = undef
    }

    $daemon_config = {} +
      dockerinstall::option('bip', $bip) +
      dockerinstall::option('mtu', $mtu) +
      dockerinstall::option('storage-driver', $storage_driver) +
      dockerinstall::option('exec-opts', $exec_opts) +
      dockerinstall::option('log-driver', $log_driver) +
      dockerinstall::option('log-opts', $log_opts) +
      dockerinstall::option('storage-opts', $storage_opts) +
      dockerinstall::option('selinux-enabled', $selinux)

    file { '/etc/docker/daemon.json':
      ensure  => $config_ensure,
      content => template('dockerinstall/daemon.json.erb'),
    }
}
