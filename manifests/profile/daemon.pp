# Docker configuration setup and daemon start
#
# @summary Docker configuration setup and daemon start
#
# @param network_bridge_ip
#   Address and mask for the default bridge (`bip`).
#
# @param mtu
#   MTU for the default bridge.
#
# @param selinux
#   Whether to enable SELinux support in the daemon.
#
# @param storage_driver
#   Storage driver to use, e.g. `overlay2`.
#
# @param storage_opts
#   Storage driver options.
#
# @param cgroup_driver
#   Cgroup driver, e.g. `systemd`.
#
# @param log_driver
#   Logging driver for containers.
#
# @param log_opts
#   Options for the logging driver. With no `log_opts` the json-file driver does
#   not rotate at all, so a chatty container grows without bound.
#
# @param docker0_bind
#   Without TLS, publish the insecure API on the docker0 address only.
#
# @param tls_enable
#   Serve the API over TLS with client-certificate verification.
#
# @param tls_users_access
#   Make the daemon's client key world-readable so unprivileged users on the
#   host can use it. Where the API is fronted by a certificate Common Name
#   allow-list, this defeats it: anything able to read the key can present the
#   name that key carries. Mutually exclusive with `tls_key_group`.
#
# @param tls_listen_ip
#   Address the TLS API binds to. `undef` keeps the historical wildcard bind, so
#   existing nodes do not move. Set it to a loopback address to take the API off
#   the network entirely, and put `dockerinstall::daemon_proxy` in front of it if
#   remote access is still wanted.
#
# @param tls_key_group
#   Group granted read access to the daemon's client key, via mode 0640 instead
#   of the default 0400. Needed when a proxy running as another user has to
#   authenticate to the daemon on clients' behalf.
#
# @example
#   include dockerinstall::profile::daemon
#
# @example API on loopback only, key readable by the nginx worker
#   class { 'dockerinstall::profile::daemon':
#     tls_enable    => true,
#     tls_listen_ip => '127.0.0.1',
#     tls_key_group => 'www-data',
#   }
class dockerinstall::profile::daemon (
  Optional[String] $network_bridge_ip = undef,
  Optional[Integer] $mtu = undef,
  Optional[Boolean] $selinux = undef,
  Optional[String] $storage_driver = undef,
  Optional[Array[String]] $storage_opts = undef,
  Optional[String] $cgroup_driver = undef,
  Optional[String] $log_driver = undef,
  Optional[Hash] $log_opts = undef,
  Boolean $docker0_bind = false,
  Boolean $tls_enable = false,
  Boolean $tls_users_access = false,
  Optional[Stdlib::IP::Address] $tls_listen_ip = undef,
  Optional[String[1]] $tls_key_group = undef,
) {
  include dockerinstall::profile::install
  include dockerinstall::params

  $docker_tlsdir = $dockerinstall::params::docker_tlsdir

  class { 'dockerinstall::tls':
    users_access => $tls_users_access,
    key_group    => $tls_key_group,
  }

  class { 'dockerinstall::config':
    bip            => $network_bridge_ip,
    mtu            => $mtu,
    selinux        => $selinux,
    storage_driver => $storage_driver,
    storage_opts   => $storage_opts,
    cgroup_driver  => $cgroup_driver,
    log_driver     => $log_driver,
    log_opts       => $log_opts,
  }

  # Daemon options
  # TLS settings
  if $tls_enable {
    $tls_settings = {
      'tls_enable' => true,
      # use Puppet CA signed certificate which does not support IP SANs
      # but uses Common Name field for FQDN
      'tls_verify' => true,
      'tls_cacert' => "${docker_tlsdir}/ca.pem",
      'tls_cert'   => "${docker_tlsdir}/cert.pem",
      'tls_key'    => "${docker_tlsdir}/key.pem",
    }

    # A wildcard bind is the historical default and stays the default here, so
    # existing nodes do not move. Setting tls_listen_ip to a loopback address is
    # what takes the API off the network - intended to be paired with a proxy in
    # front of it, see dockerinstall::daemon_proxy.
    if $tls_listen_ip {
      $tcp_bind = ["tcp://${tls_listen_ip}:2376"]
    }
    else {
      $tcp_bind = ['tcp://0.0.0.0:2376']
    }
    $tcp_bind_insecure = []
  }
  else {
    $tls_settings = {
      'tls_enable' => false,
    }

    $tcp_bind = []
    if $docker0_bind and 'docker0' in $facts['networking']['interfaces'] {
      $tcp_bind_insecure = ["${facts['networking']['interfaces']['docker0']['ip']}:2375"]
    }
    else {
      $tcp_bind_insecure = []
    }
  }

  $tcp_settings = {
    'tcp_bind' => $tcp_bind + $tcp_bind_insecure,
  }

  class { 'dockerinstall::service':
    * => $tls_settings + $tcp_settings,
  }
  contain dockerinstall::service

  class { 'dockerinstall::compose': }

  Class['dockerinstall::profile::install'] ~> Class['dockerinstall::service']
  Class['dockerinstall::tls'] ~> Class['dockerinstall::service']
  Class['dockerinstall::profile::install'] -> Class['dockerinstall::compose']
}
