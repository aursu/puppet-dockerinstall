# == Class: docker::service
#
class docker::service (
    Docker::Ensure
            $service_ensure                 = $docker::service_ensure,
    Boolean $manage_service                 = $docker::manage_service,
    String  $service_name                   = $docker::service_name,
    Boolean $service_enable                 = $docker::service_enable,
    Boolean $service_hasstatus              = $docker::service_hasstatus,
    Boolean $service_hasrestart             = $docker::service_hasrestart,
    Optional[String]
            $service_config                 = $docker::service_config,
    Optional[String]
            $service_config_template        = $docker::service_config_template,
    Optional[String]
            $service_overrides_config       = $docker::service_overrides_config,
    Optional[String]
            $service_overrides_template     = $docker::service_overrides_template,
    Optional[String]
            $storage_config                 = $docker::storage_config,
    Optional[String]
            $storage_config_template        = $docker::storage_config_template,
    Optional[String]
            $root_dir                       = $docker::root_dir,
    Optional[Docker::Multiple]
            $tcp_bind                       = $docker::tcp_bind,
    Boolean $tls_enable                     = $docker::tls_enable,
    Boolean $tls_verify                     = $docker::tls_verify,
    String  $tls_cacert                     = $docker::tls_cacert,
    String  $tls_cert                       = $docker::tls_cert,
    String  $tls_key                        = $docker::tls_key,
    Optional[Docker::Multiple]
            $socket_bind                    = $docker::socket_bind,
    Boolean $ip_forward                     = $docker::ip_forward,
    Boolean $iptables                       = $docker::iptables,
    Boolean $ip_masq                        = $docker::ip_masq,
    Boolean $icc                            = $docker::icc,
    Optional[String]
            $registry_mirror                = $docker::registry_mirror,
    Optional[String]
            $fixed_cidr                     = $docker::fixed_cidr,
    Optional[String]
            $default_gateway                = $docker::default_gateway,
    Optional[String]
            $bridge                         = $docker::bridge,
    Optional[String]
            $bip                            = $docker::bip,
    Optional[Docker::LogLevel]
            $log_level                      = $docker::log_level,
    Optional[Docker::LogDriver]
            $log_driver                     = $docker::log_driver,
    Optional[Docker::Multiple]
            $log_opt                        = $docker::log_opt,
    Boolean $selinux_enabled                = $docker::selinux_enabled,
    Optional[String]
            $socket_group                   = $docker::socket_group,
    Optional[Docker::Multiple]
            $dns                            = $docker::dns,
    Optional[Docker::Multiple]
            $dns_search                     = $docker::dns_search,
    Optional[Integer]
            $mtu                            = $docker::mtu,
    Optional[Docker::Multiple]
            $labels                         = $docker::labels,
    Optional[Docker::Multiple]
            $extra_parameters               = $docker::extra_parameters,
    Optional[String]
            $proxy                          = $docker::proxy,
    Optional[String]
            $no_proxy                       = $docker::no_proxy,
    Optional[String]
            $tmp_dir                        = $docker::tmp_dir,
    Optional[Docker::StorageDriver]
            $storage_driver                 = $docker::storage_driver,
    Optional[String]
            $dm_basesize                    = $docker::dm_basesize,
    Optional[Docker::DmFS]
            $dm_fs                          = $docker::dm_fs,
    Optional[String]
            $dm_mkfsarg                     = $docker::dm_mkfsarg,
    Optional[String]
            $dm_mountopt                    = $docker::dm_mountopt,
    Optional[String]
            $dm_blocksize                   = $docker::dm_blocksize,
    Optional[String]
            $dm_loopdatasize                = $docker::dm_loopdatasize,
    Optional[String]
            $dm_loopmetadatasize            = $docker::dm_loopmetadatasize,
    Optional[String]
            $dm_datadev                     = $docker::dm_datadev,
    Optional[String]
            $dm_metadatadev                 = $docker::dm_metadatadev,
    Optional[String]
            $dm_thinpooldev                 = $docker::dm_thinpooldev,
    Boolean $dm_use_deferred_removal        = $docker::dm_use_deferred_removal,
    Boolean $dm_use_deferred_deletion       = $docker::dm_use_deferred_deletion,
    Boolean $dm_blkdiscard                  = $docker::dm_blkdiscard,
    Boolean $dm_override_udev_sync_check    = $docker::dm_override_udev_sync_check,
    Boolean $overlay2_override_kernel_check = $docker::overlay2_override_kernel_check,
)
{
    include lsys::systemd

    if $manage_service {
        service { $service_name:
            ensure     => $service_esure,
            enable     => $service_enable,
            hasstatus  => $service_hasstatus,
            hasrestart => $service_hasrestart,
            alias      => 'docker',
        }

        file { '/etc/systemd/system/docker.service.d':
            ensure => directory,
        }

        if $service_overrides_config and $service_overrides_template {
            file { $service_overrides_config:
                ensure  => present,
                content => template($service_overrides_template),
                notify  => Exec['systemd-reload'],
                before  => Service['docker'],
            }
        }

        if $service_config and  $service_config_template {
            file { $service_config:
                ensure  => present,
                content => template($service_config_template),
                notify  => Service['docker'],
            }
        }

        if $storage_config and $storage_config_template {
            file { $storage_config:
                ensure  => present,
                content => template($storage_config_template),
                notify  => Service['docker'],
            }
        }
    }
}
