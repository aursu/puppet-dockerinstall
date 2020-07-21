# == Class: dockerinstall::install
#
# Module to install an up-to-date version of Docker from a package repository.
#
class dockerinstall::install (
    Dockerinstall::PackageName
            $package_name            = $dockerinstall::package_name,
    Dockerinstall::Version
            $version                 = $dockerinstall::version,
    Boolean $manage_package          = $dockerinstall::manage_package,
    Array[String]
            $prerequired_packages    = $dockerinstall::prerequired_packages,
    Boolean $manage_docker_certdir   = $dockerinstall::manage_docker_certdir,
    Boolean $manage_docker_tlsdir    = $dockerinstall::manage_docker_tlsdir,
    Stdlib::Unixpath
            $docker_tlsdir           = $dockerinstall::params::docker_tlsdir,
    String  $containerd_package_name = $dockerinstall::containerd_package_name,
    String  $containerd_version      = $dockerinstall::containerd_version,
) inherits dockerinstall::params
{
    include dockerinstall::repos

    if $manage_package {
        # exclude docker and conteinerd.io from list of additional packages
        $managed_packages = $prerequired_packages - [ $package_name, $containerd_package_name, 'docker', 'containerd.io']
        $managed_packages.each |String $reqp| {
            package { $reqp:
                ensure => installed,
                before => Package['docker'],
            }
        }

        package { 'docker':
            ensure => $version,
            name   => $package_name,
        }

        package { 'containerd.io':
            ensure => $containerd_version,
            name   => $containerd_package_name,
        }

        case $facts['os']['family'] {
            'Debian': {
                Apt::Source['docker'] -> Package['docker']
            }
            'RedHat': {
                Yumrepo['docker'] -> Package['docker']
            }
            default: { }
        }
    }

    file { '/etc/docker':
        ensure => directory,
    }

    if $manage_docker_certdir {
        file { '/etc/docker/certs.d':
            ensure => directory,
            owner  => 'root',
            mode   => '0700',
        }
    }

    if $manage_docker_tlsdir {
        file { $docker_tlsdir:
            ensure => directory,
            owner  => 'root',
            mode   => '0700',
        }
    }
}
