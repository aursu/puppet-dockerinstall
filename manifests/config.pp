# == Class: dockerinstall::config
#
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
)
{
    include dockerinstall::install

    if $manage_users {
        group { $group:
            ensure => 'present',
        }

        user{ $docker_users:
            ensure     => 'present',
            groups     => [ $group ],
            membership => 'minimum',
            require    => Group[$group],
            alias      => 'docker',
        }

        if $manage_package {
            Package['docker'] -> Group[$group]
            Package['docker'] -> User[$docker_users]
        }
    }

    $daemon_config = {} +
      dockerinstall::option('bip', $bip) +
      dockerinstall::option('mtu', $mtu)

    file { '/etc/docker/daemon.json':
      content => template('dockerinstall/daemon.json.erb'),
    }
}
