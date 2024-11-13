# @summary Docker repository managemennt
#
# Docker repository managemennt
#
# @example
#   include dockerinstall::repos
class dockerinstall::repos (
  Boolean $manage_package = $dockerinstall::manage_package,
  Dockerinstall::Repo $repo = $dockerinstall::repo,
  String $location = $dockerinstall::repo_location,
  Boolean $gpgcheck = $dockerinstall::repo_gpgcheck,
  Boolean $sslverify = $dockerinstall::repo_sslverify,
  String $basearch = $facts['os']['architecture'],
  Enum['present', 'absent'] $repo_ensure = 'present',
  Optional[Dockerinstall::RepoOS] $os = $dockerinstall::repo_os,
) {
  # https://docs.docker.com/install/linux/docker-ce/fedora/#set-up-the-repository
  # https://docs.docker.com/install/linux/docker-ce/centos/#set-up-the-repository
  if $os {
    $distrourl = "${location}/${os}"
    $releasever = $facts['os']['release']['major']
    $rpmurl = "${distrourl}/${releasever}/${basearch}/${repo}"
    $gpgkey = "${distrourl}/gpg"

    if $manage_package {
      if $facts['os']['family'] == 'Debian' {
        # https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
        exec { 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/trusted.gpg.d/docker.asc':
          path   => '/usr/bin:/bin',
          unless => 'gpg /etc/apt/trusted.gpg.d/docker.asc',
          before => Apt::Source['cri-o'],
        }

        apt::source { 'docker':
          comment      => 'docker apt repository',
          location     => 'https://download.docker.com/linux/ubuntu',
          release      => $facts['os']['distro']['codename'],
          repos        => 'stable',
          architecture => $facts['os']['architecture'],
          keyring      => '/etc/apt/keyrings/docker.asc',
        }
      }
      else {
        $gpgcheck_param = $gpgcheck ? {
          true    => '1',
          default => '0',
        }
        $sslverify_param = $sslverify ? {
          true    => '1',
          default => '0',
        }
        yumrepo { 'docker':
          ensure    => $repo_ensure,
          descr     => 'Docker',
          baseurl   => $rpmurl,
          gpgkey    => $gpgkey,
          gpgcheck  => $gpgcheck_param,
          sslverify => $sslverify_param,
        }
        file { '/etc/yum.repos.d/docker.repo':
          ensure => $repo_ensure,
          mode   => '0644',
        }
      }
    }
  }
}
