class dockerinstall (
    Dockerinstall::PackageName
            $package_name,
    Dockerinstall::Version
            $version,
    Boolean $manage_package,
    Dockerinstall::Repo
            $repo,
    String  $repo_location,
    Dockerinstall::RepoOS
            $repo_os,
    Boolean $repo_gpgcheck,
    Array[String]
            $prerequired_packages,
    Boolean $manage_os_users,
    Dockerinstall::UserList
            $docker_users,
    String  $docker_group,
    Boolean $manage_service,
    Dockerinstall::Ensure
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
    Optional[Dockerinstall::Multiple]
            $tcp_bind,
    Boolean $tls_enable,
    Boolean $tls_verify,
    String  $tls_cacert,
    String  $tls_cert,
    String  $tls_key,
    Optional[Dockerinstall::Multiple]
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
    Optional[Dockerinstall::LogLevel]
            $log_level,
    Optional[Dockerinstall::LogDriver]
            $log_driver,
    Optional[Dockerinstall::Multiple]
            $log_opt,
    Boolean $selinux_enabled,
    Optional[String]
            $socket_group,
    Optional[Dockerinstall::Multiple]
            $dns,
    Optional[Dockerinstall::Multiple]
            $dns_search,
    Optional[Integer]
            $mtu,
    Optional[Dockerinstall::Multiple]
            $labels,
    Optional[Dockerinstall::Multiple]
            $extra_parameters,
    Optional[String]
            $proxy,
    Optional[String]
            $no_proxy,
    Optional[String]
            $tmp_dir,
    Optional[Dockerinstall::StorageDriver]
            $storage_driver,
    Optional[String]
            $dm_basesize,
    Optional[Dockerinstall::DmFS]
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
    Optional[String]
            $compose_version,
    Boolean $manage_docker_certdir,
){}
