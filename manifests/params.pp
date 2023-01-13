# @summary Module parameters
#
# @example
#   include dockerinstall::params
class dockerinstall::params {
  if $facts['systemd'] {
    $service_config_template = 'dockerinstall/docker.systemd.erb'
  }
  else {
    $service_config_template = 'dockerinstall/docker.upstart.erb'
  }

  $docker_plugins_dir = '/usr/libexec/docker/cli-plugins'

  # predefined Docker Compose version - could  be overriden with dockerinstall::compose_version
  $compose_version          = '2.10.2'
  $compose_download_source  = 'https://github.com/docker/compose/releases/download'

  # docker compose project provides binaries only for x86_64 architecture
  # for Windows, Linux and Darwin
  # see https://github.com/docker/compose/releases
  $compose_download_name    = 'docker-compose-Linux-x86_64'
  $composev2_download_name  = 'docker-compose-linux-x86_64'
  $compose_checksum_command = 'sha256sum'
  $download_tmpdir          = '/tmp'
  $compose_binary_path      = '/usr/local/bin/docker-compose'
  $compose_rundir           = '/run/compose'
  $compose_plugin_path      = "${docker_plugins_dir}/docker-compose"

  case $facts['os']['family'] {
    'Debian': {
      case $facts['os']['name'] {
        'Ubuntu': {
          $repo_os = 'ubuntu'
        }
        default: {
          $repo_os = 'debian'
        }
      }
      $service_config = '/etc/default/docker'
      $storage_config = '/etc/default/docker-storage'
    }
    # default is RedHat based systems (CentOS)
    default: {
      $repo_os = $facts['os']['name'] ? {
        'Fedora' => 'fedora',
        default  => 'centos',
      }
      $service_config = '/etc/sysconfig/docker'
      $storage_config = '/etc/sysconfig/docker-storage'
    }
  }

  $compose_libdir = '/var/lib/compose'

  # Client authentication
  if $facts['puppet_sslpaths'] {
    $certdir       = $facts['puppet_sslpaths']['certdir']['path']
    $privatekeydir = $facts['puppet_sslpaths']['privatekeydir']['path']
  }
  else {
    # fallback to predefined
    $certdir       = '/etc/puppetlabs/puppet/ssl/certs'
    $privatekeydir = '/etc/puppetlabs/puppet/ssl/private_keys'
  }

  if $facts['clientcert'] {
    $certname = $facts['clientcert']
  }
  else {
    # fallback to fqdn
    $certname = $facts['networking']['fqdn']
  }

  $localcacert   = "${certdir}/ca.pem"
  # https://puppet.com/docs/puppet/5.3/lang_facts_and_builtin_vars.html#puppet-agent-facts
  $hostcert      = "${certdir}/${certname}.pem"
  $hostprivkey   = "${privatekeydir}/${certname}.pem"

  # Swarm data
  $swarm = $facts['docker_swarm']
  if $swarm {
    $swarm_enabled = ($swarm['LocalNodeState'] == 'active')
  }
  else {
    $swarm_enabled = undef
  }

  if $swarm_enabled {
    $is_swarm_manager = $swarm['ControlAvailable']
  }
  else {
    $is_swarm_manager = undef
  }

  $docker_tlsdir = '/etc/docker/tls'
}
