# @summary Repository metadata update
#
# Repository metadata update
#
# @example
#   include dockerinstall::repos::update
class dockerinstall::repos::update {
  case $facts['os']['family'] {
    'Debian': {
      exec { 'apt-update-59b322f':
        command     => 'apt update',
        path        => '/bin:/usr/bin',
        refreshonly => true,
      }
    }
    # default is RedHat based systems (CentOS/Rocky)
    default: {
      $reload_command = $facts['os']['release']['major'] ? {
        '7'     => 'yum clean all',
        default => 'dnf clean all',
      }

      exec { 'yum-reload-59b322f':
        command     => $reload_command,
        path        => '/bin:/usr/bin',
        refreshonly => true,
      }
    }
  }
}
