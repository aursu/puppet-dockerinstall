# == Class: dockerinstall::repos
#
#
class dockerinstall::repos (
    Boolean $manage_package         = $dockerinstall::manage_package,
    Dockerinstall::Repo
            $repo                   = $dockerinstall::repo,
    String  $location               = $dockerinstall::repo_location,
    Dockerinstall::RepoOS
            $os                     = $dockerinstall::repo_os,
    Boolean $gpgcheck               = $dockerinstall::repo_gpgcheck,
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
