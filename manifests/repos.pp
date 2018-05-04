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
    String  $basearch               = $::architecture,
    String  $releasever             = $::operatingsystemmajrelease,
)
{
    # https://docs.docker.com/install/linux/docker-ce/fedora/#set-up-the-repository
    # https://docs.docker.com/install/linux/docker-ce/centos/#set-up-the-repository
    $baseurl = "${location}/${os}/${releasever}/${basearch}/${repo}"
    $gpgkey = "${location}/${os}/gpg"

    if $manage_package {
        yumrepo { 'docker':
            descr    => 'Docker',
            baseurl  => $baseurl,
            gpgkey   => $gpgkey,
            gpgcheck => $gpgcheck,
        }
    }
}
