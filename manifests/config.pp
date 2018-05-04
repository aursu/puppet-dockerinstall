# == Class: docker::config
#
class docker::config (
    Boolean $manage_users   = $docker::manage_os_users,
    Docker::UserList
            $docker_users   = $docker::docker_users,
    String  $group          = $docker::docker_group,
)
{
    if $manage_users {
        user{ $docker_users:
            ensure     => 'present',
            groups     => [ $group ],
            membership => 'minimum',
            tag        => 'docker',
        }
    }
}
