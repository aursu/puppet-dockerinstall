# @summary Docker daemon installation from package repository.
#
# Docker daemon installation from package repository.
#
# @example
#   include dockerinstall::install
class dockerinstall::install (
    Dockerinstall::PackageName
            $package_name            = $dockerinstall::package_name,
    Dockerinstall::Version
            $version                 = $dockerinstall::version,
    Boolean $manage_package          = $dockerinstall::manage_package,
    Array[String]
            $prerequired_packages    = $dockerinstall::prerequired_packages,
    String  $containerd_package_name = $dockerinstall::containerd_package_name,
    String  $containerd_version      = $dockerinstall::containerd_version,
    Boolean $manage_cli              = $dockerinstall::manage_cli,
    String  $cli_package_name        = $dockerinstall::cli_package_name,
)
{
    include dockerinstall::setup

    if $manage_package {
        include dockerinstall::repos

        # exclude docker and conteinerd.io from list of additional packages
        $managed_packages = $prerequired_packages - [ $package_name, $containerd_package_name, 'docker', 'containerd.io']
        $managed_packages.each |String $reqp| {
            package { $reqp:
                ensure => installed,
                before => Package['docker'],
            }
        }

        package { 'docker':
            ensure  => $version,
            name    => $package_name,
            require => Class['dockerinstall::repos'],
        }

        if $manage_cli {
            package { 'docker-cli':
                ensure => $version,
                name   => $cli_package_name,
            }
        }

        package { 'containerd.io':
            ensure => $containerd_version,
            name   => $containerd_package_name,
        }
    }
}
