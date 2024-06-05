# @summary Docker installation
#
# Docker installation (installation only)
#
# @example
#   include dockerinstall::profile::install
class dockerinstall::profile::install (
  Optional[String] $dockerd_version    = undef,
  Optional[String] $containerd_version = undef,
  Boolean $tls_users_access = false,
) {
  include dockerinstall

  class { 'dockerinstall::setup':
    manage_docker_tlsdir => true,
    users_access         => $tls_users_access,
  }

  class { 'dockerinstall::install':
    version            => $dockerd_version,
    containerd_version => $containerd_version,
  }
  contain dockerinstall::install
}
