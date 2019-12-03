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
    if $::operatingsystem == 'Ubuntu' {
      if $repo_mgmt_software {
        package {
          [
            'apt-transport-https',
            'software-properties-common',
          ]:
          ensure => installed,
        }
      }

      # https://docs.docker.com/install/linux/docker-ce/ubuntu/
      $aptrepo = "deb [arch=${basearch}] ${distrourl} ${::lsbdistcodename} ${repo}"
      exec { 'aptrepo-docker':
        command => "add-apt-repository \"${aptrepo}\"",
        unless  => "grep ${distrourl} /etc/apt/sources.list",
        path    => '/bin:/usr/bin',
      }
      if $gpgcheck {
        exec { 'aptrepo-docker-gpgkey':
          command => "curl -fsSL ${gpgkey} | apt-key add -",
          unless  => 'apt-key fingerprint 0EBFCD88 | grep Docker',
          path    => '/bin:/usr/bin',
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
