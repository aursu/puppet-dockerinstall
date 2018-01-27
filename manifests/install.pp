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
)
{
    if $manage_package {
        package { 'docker':
            ensure   => $version,
            name     => $package_name,
        }
    }
}
