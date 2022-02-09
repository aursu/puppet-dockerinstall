# @summary Repository metadata update
#
# Repository metadata update
#
# @example
#   include dockerinstall::repos::update
class dockerinstall::repos::update {
  if $facts['os']['name'] == 'Ubuntu' {
    exec { 'apt-update-59b322f':
      command     => 'apt update',
      path        => '/bin:/usr/bin',
      refreshonly => true,
    }
  }
  elsif  $facts['os']['name'] == 'CentOS' {
    exec { 'yum-reload-59b322f':
      command     => 'yum clean all',
      path        => '/bin:/usr/bin',
      refreshonly => true,
    }
  }
}
