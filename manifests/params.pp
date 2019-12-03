# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include dockerinstall::params
class dockerinstall::params {
    if $::is_init_systemd {
        $service_config_template = 'dockerinstall/docker.systemd.erb'
    }
    else {
        $service_config_template = 'dockerinstall/docker.upstart.erb'
    }
    $compose_version          = '1.25.0'
    $compose_download_source  = 'https://github.com/docker/compose/releases/download'

    # docker compose project provides binaries only for x86_64 architecture
    # for Windows, Linux and Darwin
    # see https://github.com/docker/compose/releases
    $compose_download_name    = 'docker-compose-Linux-x86_64'
    $compose_checksum_name    = "${compose_download_name}.sha256"
    $compose_checksum_command = 'sha256sum'
    $download_tmpdir          = '/tmp'
    $compose_binary_path      = '/usr/local/bin/docker-compose'

    if  $facts['os']['name'] in ['RedHat', 'CentOS'] and
        $facts['os']['release']['major'] in ['7', '8'] {
        $compose_rundir = '/run/compose'
    }
    else {
        $compose_rundir = '/var/run/compose'
    }
    $compose_libdir = '/var/lib/compose'

    # Client authentication
    $certdir       = $::puppet_sslpaths['certdir']['path']
    $privatekeydir = $::puppet_sslpaths['privatekeydir']['path']
    $localcacert   = "${certdir}/ca.pem"
    # https://puppet.com/docs/puppet/5.3/lang_facts_and_builtin_vars.html#puppet-agent-facts
    $hostcert      = "${certdir}/${::clientcert}.pem"
    $hostprivkey   = "${privatekeydir}/${::clientcert}.pem"

    # Swarm data
    $swarm = $::docker_swarm
    $swarm_enabled = ($swarm['LocalNodeState'] == 'active')
    if $swarm_enabled {
        $is_swarm_manager = $swarm['ControlAvailable']
    }
    else {
        $is_swarm_manager = undef
    }
}
