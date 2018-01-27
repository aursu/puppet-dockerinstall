# == Class: docker::repos
#
#
class docker::repos (
    Boolean $manage_package         = $docker::manage_package,
    Docker::Repo
            $repo                   = $docker::repo,
    String  $location               = $docker::repo_location,
    Docker::RepoOS
            $os                     = $docker::repo_os,
    Boolean $gpgcheck               = $docker::repo_gpgcheck,
    Array[String]
            $prerequired_packages   = $docker::prerequired_packages,
)
{
    $prerequired_packages.each |String $reqp| {
        package { $reqp:
            ensure => installed,
        }
    }

    $baseurl = "${location}/${os}/${::operatingsystemmajrelease}/${::architecture}/${repo}"
    $gpgkey = "${location}/${os}/gpg"

    if ($manage_package) {
        yumrepo { 'docker':
            descr    => 'Docker',
            baseurl  => $baseurl,
            gpgkey   => $gpgkey,
            gpgcheck => $gpgcheck,
        }
        Yumrepo['docker'] -> Package <| name == 'docker' |>
    }
}
