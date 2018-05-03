# == Class: docker::install
#
# Module to install an up-to-date version of Docker from a package repository.
#
class docker::install (
    Docker::PackageName
            $package_name   = $docker::package_name,
    Docker::Version
            $version        = $docker::version,
    Boolean $manage_package = $docker::manage_package,
    Array[String]
            $prerequired_packages   = $docker::prerequired_packages,
)
{
    $prerequired_packages.each |String $reqp| {
        package { $reqp:
            ensure => installed,
        }
    }

    if $manage_package {
        package { $package_name:
            ensure => $version,
            name   => $package_name,
            alias  => 'docker',
        }
    }
}
