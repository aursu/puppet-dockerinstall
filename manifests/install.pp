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
            ensure  => $version,
            name    => $package_name,
            require => Yumrepo['docker'],
            alias   => 'docker',
        }
    }

    if $manage_docker_certdir {
        file { '/etc/docker/certs.d':
            ensure => directory,
        }
    }
}
