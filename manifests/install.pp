# == Class: dockerinstall::install
#
# Module to install an up-to-date version of Docker from a package repository.
#
class dockerinstall::install (
    Dockerinstall::PackageName
            $package_name   = $dockerinstall::package_name,
    Dockerinstall::Version
            $version        = $dockerinstall::version,
    Boolean $manage_package = $dockerinstall::manage_package,
    Array[String]
            $prerequired_packages   = $dockerinstall::prerequired_packages,
)
{
    include dockerinstall::repos

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
        Yumrepo <| title == 'docker' |> -> Package[$package_name]
    }
}
