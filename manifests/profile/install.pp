# @summary Docker installation
#
# Docker installation (installation only)
#
# @example
#   include dockerinstall::profile::install
class dockerinstall::profile::install (
  Optional[String]
          $dockerd_version = undef,
  Stdlib::Unixpath
          $docker_tlsdir   = $dockerinstall::params::docker_tlsdir,
) inherits dockerinstall::params
{
  class { 'dockerinstall': }
  class { 'dockerinstall::install':
    version              => $dockerd_version,
    manage_docker_tlsdir => true,
    docker_tlsdir        => $docker_tlsdir,
  }
}
