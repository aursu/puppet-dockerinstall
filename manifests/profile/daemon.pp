# Docker configuration setup and daemon  start
#
# @summary Docker configuration setup and daemon  start
#
# @example
#   include dockerinstall::profile::daemon
class dockerinstall::profile::daemon (
  Optional[String]
          $network_bridge_ip = undef,
  Optional[Integer]
          $mtu               = undef,
  Optional[String]
          $storage_driver    = undef,
  Optional[Array[String]]
          $storage_opts      = undef,
  Optional[String]
          $cgroup_driver     = undef,
  Optional[String]
          $log_driver        = undef,
  Optional[Hash]
          $log_opts          = undef,
  Boolean $docker0_bind      = false,
  Boolean $tls_enable        = false,
  Stdlib::Unixpath
          $docker_tlsdir   = $dockerinstall::params::docker_tlsdir,
) inherits dockerinstall::params
{
    include dockerinstall::profile::install

    class { 'dockerinstall::tls':
      docker_tlsdir => $docker_tlsdir,
    }

    class { 'dockerinstall::config':
      bip            => $network_bridge_ip,
      mtu            => $mtu,
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

        $tcp_bind = [ 'tcp://0.0.0.0:2376' ]
        $tcp_bind_insecure = []
    }
    else {
        $tls_settings = {
            'tls_enable' => false,
        }

        $tcp_bind = []
        if $docker0_bind and 'docker0' in $::networking['interfaces'] {
          $tcp_bind_insecure = [ "${::networking['interfaces']['docker0']['ip']}:2375" ]
        }
        else {
          $tcp_bind_insecure = []
        }
    }

    $tcp_settings = {
        'tcp_bind' => $tcp_bind + $tcp_bind_insecure
    }

    class { 'dockerinstall::service':
        * =>  $tls_settings +
              $tcp_settings,
    }

    class { 'dockerinstall::compose': }
}

