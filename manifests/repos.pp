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
  Dockerinstall::RepoOS $os = $dockerinstall::repo_os,
  Boolean $gpgcheck = $dockerinstall::repo_gpgcheck,
  Boolean $sslverify = $dockerinstall::repo_sslverify,
  String $basearch = $facts['os']['architecture'],
  Enum['present', 'absent'] $repo_ensure = 'present',
) {
  # https://docs.docker.com/install/linux/docker-ce/fedora/#set-up-the-repository
  # https://docs.docker.com/install/linux/docker-ce/centos/#set-up-the-repository
  $distrourl = "${location}/${os}"
  $releasever = $facts['os']['release']['major']
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
          id     => '9DC858229FC7DD38854AE2D88D81803C0EBFCD88',
          source => $gpgkey,
        },
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
