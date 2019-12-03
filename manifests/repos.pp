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
    Boolean $repo_mgmt_software     = $dockerinstall::repo_management_software,
)
{
  # https://docs.docker.com/install/linux/docker-ce/fedora/#set-up-the-repository
  # https://docs.docker.com/install/linux/docker-ce/centos/#set-up-the-repository
  $distrourl = "${location}/${os}"
  $rpmurl = "${distrourl}/${releasever}/${basearch}/${repo}"
  $gpgkey = "${distrourl}/gpg"

  if $manage_package {
    if $facts['os']['family'] == 'Debian' {
      # https://docs.docker.com/install/linux/docker-ce/ubuntu/
      apt::source { 'docker':
        architecture => $basearch,
        location     => $distrourl,
        repos        => $repo,
        key          => {
          id     => '0EBFCD88',
          source => $gpgkey,
        }
      }
    }
    else {
      yumrepo { 'docker':
        descr    => 'Docker',
        baseurl  => $rpmurl,
        gpgkey   => $gpgkey,
        gpgcheck => $gpgcheck,
      }
    }
  }
}
