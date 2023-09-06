# @summary Registry token authentication basic setup
#
# Registry token authentication basic setup
#
# @example
#   include dockerinstall::registry::setup::token
class dockerinstall::registry::setup::token (
) inherits dockerinstall::registry::params {
  include dockerinstall::setup

  $tokenbundle_certdir = $dockerinstall::registry::params::tokenbundle_certdir

  file { $tokenbundle_certdir:
    ensure => directory,
  }
}
