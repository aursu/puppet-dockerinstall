# @summary Base profile for Docker registry client auth setup
#
# Base profile for Docker registry client auth setup
#
# @example
#   include dockerinstall::profile::registry::clientauth
class dockerinstall::profile::registry::clientauth (
  Optional[Array[Stdlib::Fqdn]] $registry = undef,
) {
  include dockerinstall
  include dockerinstall::setup

  if $registry {
    $registry.each |$server_name| {
      dockerinstall::registry::clientauth { $server_name: }

      dockerinstall::registry::clientauth { "${server_name}:443":
        server_name => $server_name,
        server_port => 443,
      }
    }
  }
}
