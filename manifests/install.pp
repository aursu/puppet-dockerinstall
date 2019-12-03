# == Class: dockerinstall::install
#
# Module to install an up-to-date version of Docker from a package repository.
#
class dockerinstall::install (
    Dockerinstall::PackageName
            $package_name          = $dockerinstall::package_name,
    Dockerinstall::Version
            $version               = $dockerinstall::version,
    Boolean $manage_package        = $dockerinstall::manage_package,
    Array[String]
            $prerequired_packages  = $dockerinstall::prerequired_packages,
    Boolean $manage_docker_certdir = $dockerinstall::manage_docker_certdir,
    Boolean $manage_docker_tlsdir  = $dockerinstall::manage_docker_tlsdir,
    Stdlib::Unixpath
            $docker_tlsdir         = $dockerinstall::docker_tlsdir,
)
{
    include dockerinstall::repos

    if $manage_package {
        $prerequired_packages.each |String $reqp| {
            package { $reqp:
                ensure => installed,
                before => Package['docker'],
            }
        }

        package { $package_name:
            ensure => $version,
            name   => $package_name,
            alias  => 'docker',
        }

        case $facts['os']['family'] {
            'Debian': {
                Apt::Source['docker'] -> Package[$package_name]
            }
            'RedHat': {
                Yumrepo['docker'] -> Package[$package_name]
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
