# == Class: dockerinstall::config
#
class dockerinstall::config (
    Boolean $manage_users   = $dockerinstall::manage_os_users,
    Dockerinstall::UserList
            $docker_users   = $dockerinstall::docker_users,
    String  $group          = $dockerinstall::docker_group,
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
