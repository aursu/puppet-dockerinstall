class docker (
    Docker::PackageName
            $package_name,
    Docker::Version
            $version,
    Boolean $manage_package,
    Docker::Repo
            $repo,
    String  $repo_location,
    Docker::RepoOS
            $repo_os,
    Boolean $repo_gpgcheck,
    Array[String]
            $prerequired_packages,
    Boolean $manage_os_users,
    Docker::UserList
            $docker_users,
    String  $docker_group,
    Boolean $manage_service,
    Docker::Ensure
            $service_ensure,
    String  $service_name,
    Boolean $service_enable,
    Boolean $service_hasstatus,
    Boolean $service_hasrestart,
    Optional[String]
            $service_overrides_config,
    Optional[String]
            $service_overrides_template,
    Optional[String]
            $service_config,
    Optional[String]
            $service_config_template,
    Optional[String]
            $storage_config,
    Optional[String]
            $storage_config_template,
    Optional[String]
            $root_dir,
    Optional[Docker::Multiple]
            $tcp_bind,
    Boolean $tls_enable,
    Boolean $tls_verify,
    String  $tls_cacert,
    String  $tls_cert,
    String  $tls_key,
    Optional[Docker::Multiple]
            $socket_bind,
    Boolean $ip_forward,
    Boolean $iptables,
    Boolean $ip_masq,
    Boolean $icc,
    Optional[String]
            $registry_mirror,
    Optional[String]
            $fixed_cidr,
    Optional[String]
            $default_gateway,
    Optional[String]
            $bridge,
    Optional[String]
            $bip,
    Optional[Docker::LogLevel]
            $log_level,
    Optional[Docker::LogDriver]
            $log_driver,
    Optional[Docker::Multiple]
            $log_opt,
    Boolean $selinux_enabled,
    Optional[String]
            $socket_group,
    Optional[Docker::Multiple]
            $dns,
    Optional[Docker::Multiple]
            $dns_search,
    Optional[Integer]
            $mtu,
    Optional[Docker::Multiple]
            $labels,
    Optional[Docker::Multiple]
            $extra_parameters,
    Optional[String]
            $proxy,
    Optional[String]
            $no_proxy,
    Optional[String]
            $tmp_dir,
    Optional[Docker::StorageDriver]
            $storage_driver,
    Optional[String]
            $dm_basesize,
    Optional[Docker::DmFS]
            $dm_fs,
    Optional[String]
            $dm_mkfsarg,
    Optional[String]
            $dm_mountopt,
    Optional[String]
            $dm_blocksize,
    Optional[String]
            $dm_loopdatasize,
    Optional[String]
            $dm_loopmetadatasize,
    Optional[String]
            $dm_datadev,
    Optional[String]
            $dm_metadatadev,
    Optional[String]
            $dm_thinpooldev,
    Boolean $dm_use_deferred_removal,
    Boolean $dm_use_deferred_deletion,
    Boolean $dm_blkdiscard,
    Boolean $dm_override_udev_sync_check,
    Boolean $overlay2_override_kernel_check,
)
{
    # to install Docker CE - use: include 'docker::install'
    # to install and run Docker CE - use: include 'docker::service'
}
