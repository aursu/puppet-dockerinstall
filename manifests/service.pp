# @summary Docker service managemennt
#
# Docker service managemennt
#
# @param service_config
#   Docker service environment config (eg /etc/sysconfig/docker
#   on Red Hat based)
#   set OPTIONS environment variable
#
# @param storage_config
#   Docker service environment config for storage driver options
#   set DOCKER_STORAGE_OPTIONS environment variable
#
# @example
#   include dockerinstall::service
class dockerinstall::service (
  Dockerinstall::Ensure $service_ensure = $dockerinstall::service_ensure,
  Boolean $manage_service                 = $dockerinstall::manage_service,
  String  $service_name                   = $dockerinstall::service_name,
  Boolean $service_enable                 = $dockerinstall::service_enable,
  Boolean $service_hasstatus              = $dockerinstall::service_hasstatus,
  Boolean $service_hasrestart             = $dockerinstall::service_hasrestart,
  Optional[String] $service_config = $dockerinstall::service_config,
  Optional[String] $service_config_template = $dockerinstall::service_config_template,
  Optional[String] $service_overrides_config = $dockerinstall::service_overrides_config,
  Optional[String] $service_overrides_template = $dockerinstall::service_overrides_template,
  Optional[String] $storage_config = $dockerinstall::storage_config,
  Optional[String] $storage_config_template = $dockerinstall::storage_config_template,
  Optional[String] $root_dir = $dockerinstall::root_dir,
  Optional[Dockerinstall::Multiple] $tcp_bind = $dockerinstall::tcp_bind,
  Boolean $tls_enable                     = $dockerinstall::tls_enable,
  Boolean $tls_verify                     = $dockerinstall::tls_verify,
  String  $tls_cacert                     = $dockerinstall::tls_cacert,
  String  $tls_cert                       = $dockerinstall::tls_cert,
  String  $tls_key                        = $dockerinstall::tls_key,
  Optional[Dockerinstall::Multiple] $socket_bind = $dockerinstall::socket_bind,
  Boolean $ip_forward                     = $dockerinstall::ip_forward,
  Boolean $iptables                       = $dockerinstall::iptables,
  Boolean $ip_masq                        = $dockerinstall::ip_masq,
  Boolean $icc                            = $dockerinstall::icc,
  Optional[String] $registry_mirror = $dockerinstall::registry_mirror,
  Optional[String] $fixed_cidr = $dockerinstall::fixed_cidr,
  Optional[String] $default_gateway = $dockerinstall::default_gateway,
  Optional[String] $bridge = $dockerinstall::bridge,
  Optional[String] $bip = $dockerinstall::bip,
  Optional[Dockerinstall::LogLevel] $log_level = $dockerinstall::log_level,
  Optional[Dockerinstall::LogDriver] $log_driver = $dockerinstall::log_driver,
  Optional[Dockerinstall::Multiple] $log_opt = $dockerinstall::log_opt,
  Boolean $selinux_enabled = $dockerinstall::selinux_enabled,
  Optional[String] $socket_group = $dockerinstall::socket_group,
  Optional[Dockerinstall::Multiple] $dns = $dockerinstall::dns,
  Optional[Dockerinstall::Multiple] $dns_search = $dockerinstall::dns_search,
  Optional[Integer] $mtu = $dockerinstall::mtu,
  Optional[Dockerinstall::Multiple] $labels = $dockerinstall::labels,
  Optional[Dockerinstall::Multiple] $extra_parameters = $dockerinstall::extra_parameters,
  Optional[String] $proxy = $dockerinstall::proxy,
  Optional[String] $no_proxy = $dockerinstall::no_proxy,
  Optional[String] $tmp_dir = $dockerinstall::tmp_dir,
  Optional[Dockerinstall::StorageDriver] $storage_driver = $dockerinstall::storage_driver,
  Optional[String] $dm_basesize = $dockerinstall::dm_basesize,
  Optional[Dockerinstall::DmFS] $dm_fs = $dockerinstall::dm_fs,
  Optional[String] $dm_mkfsarg = $dockerinstall::dm_mkfsarg,
  Optional[String] $dm_mountopt = $dockerinstall::dm_mountopt,
  Optional[String] $dm_blocksize = $dockerinstall::dm_blocksize,
  Optional[String] $dm_loopdatasize = $dockerinstall::dm_loopdatasize,
  Optional[String] $dm_loopmetadatasize = $dockerinstall::dm_loopmetadatasize,
  Optional[String] $dm_datadev = $dockerinstall::dm_datadev,
  Optional[String] $dm_metadatadev = $dockerinstall::dm_metadatadev,
  Optional[String] $dm_thinpooldev = $dockerinstall::dm_thinpooldev,
  Boolean $dm_use_deferred_removal        = $dockerinstall::dm_use_deferred_removal,
  Boolean $dm_use_deferred_deletion       = $dockerinstall::dm_use_deferred_deletion,
  Boolean $dm_blkdiscard                  = $dockerinstall::dm_blkdiscard,
  Boolean $dm_override_udev_sync_check    = $dockerinstall::dm_override_udev_sync_check,
  Boolean $overlay2_override_kernel_check = $dockerinstall::overlay2_override_kernel_check,
  Boolean $manage_users                   = $dockerinstall::manage_os_users,
  Boolean $manage_package                 = $dockerinstall::manage_package,
  String $service_config_ensure = 'file',
) {
  include dockerinstall::config
  include dockerinstall::params

  if $manage_service {
    service { 'docker':
      ensure     => $service_ensure,
      name       => $service_name,
      enable     => $service_enable,
      hasstatus  => $service_hasstatus,
      hasrestart => $service_hasrestart,
    }

    if $service_config_template {
      # provided by user
      $config_template = $service_config_template
    }
    else {
      # predefined (systemd or upstart)
      $config_template = $dockerinstall::params::service_config_template
    }

    if $service_config {
      file { $service_config:
        ensure  => $service_config_ensure,
        content => template($config_template),
      }
      if $service_config_ensure == 'file' {
        File[$service_config] ~> Service['docker']
      }
    }

    if $facts['systemd'] {
      if $service_overrides_config and $service_overrides_template {
        systemd::dropin_file { 'docker-service-overrides':
          ensure   => $service_config_ensure,
          filename => 'service-overrides.conf',
          unit     => 'docker.service',
          content  => template($service_overrides_template),
        }
        if $service_config {
          File[$service_config] -> Systemd::Dropin_file['docker-service-overrides']
        }
        if $service_config_ensure == 'file' {
          Class['dockerinstall::config']
          -> Systemd::Dropin_file['docker-service-overrides']
          -> Service['docker']
        }
      }
    }

    # for Upstart it is integrated into $service_config
    if $storage_config and $storage_config_template {
      file { $storage_config:
        ensure  => $service_config_ensure,
        content => template($storage_config_template),
      }
      if $service_config_ensure == 'file' {
        File[$storage_config] ~> Service['docker']
      }
    }

    if $service_ensure == 'running' {
      include dockerinstall::install

      Class['dockerinstall::config'] ~> Service['docker']
      Class['dockerinstall::install'] -> Service['docker']
    }
  }
}
