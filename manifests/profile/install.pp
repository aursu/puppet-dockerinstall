# @summary Docker installation
#
# Docker installation (installation only)
#
# @example
#   include dockerinstall::profile::install
class dockerinstall::profile::install (
  Optional[String] $dockerd_version    = undef,
  Optional[String] $containerd_version = undef,
  Stdlib::Unixpath $docker_tlsdir = $dockerinstall::params::docker_tlsdir,
  Boolean $tls_users_access = false,
) inherits dockerinstall::params {
  include dockerinstall

  class { 'dockerinstall::setup':
    manage_docker_tlsdir => true,
    docker_tlsdir        => $docker_tlsdir,
    users_access         => $tls_users_access,
  }

  class { 'dockerinstall::install':
    version            => $dockerd_version,
    containerd_version => $containerd_version,
  }
  contain dockerinstall::install
}
