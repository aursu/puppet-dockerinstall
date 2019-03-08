# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include dockerinstall::swarm::manager
class dockerinstall::swarm::manager (
  Boolean $enable = true,
  Optional[Stdlib::IP::Address]
          $advertise_addr = undef,
  Optional[
    Variant[
      Stdlib::Fqdn,
      Stdlib::IP::Address
    ]
  ]       $manager_node = undef,
)
{
  include dockerinstall::params
  $swarm_enabled = $dockerinstall::params::swarm_enabled
  $is_manager    = $dockerinstall::params::is_swarm_manager
  $swarm         = $dockerinstall::params::swarm

  # check advertise address (no IPv6 support now)
  if $advertise_addr {
    $node_ip_addresses = $::networking['interfaces'].map |$iface, $ipdata| { $ipdata['ip'] }
    unless $advertise_addr in $node_ip_addresses {
      fail('The address to advertise is not recognized as a system address')
    }
  }

  $node_name = $::fqdn
  $nodeid = $swarm['NodeID']

  if $enable {
    if $swarm_enabled {
      if $is_manager {
        if $advertise_addr {
          # export nodes
          @@dockerinstall::swarm::node { "worker/${node_name}":
            join_token      => $swarm['JoinTokens']['Worker'],
            manager_node_ip => $advertise_addr,
          }

          @@dockerinstall::swarm::node { "manager/${node_name}":
            join_token      => $swarm['JoinTokens']['Manager'],
            manager_node_ip => $advertise_addr,
          }

          # Promote hosts (tag as IP address)
          Dockerinstall::Swarm::Promote <<| tag == $advertise_addr |>>
        }

        # Promote hosts (tag as hostname)
        Dockerinstall::Swarm::Promote <<| tag == $node_name |>>
      }
      # if it is worker - export its promotion
      elsif $manager_node {
        @@dockerinstall::swarm::promote { $nodeid:
          tag => $manager_node,
        }
      }
    }
    else {
      if $advertise_addr {
        # init swarm manager
        exec { "docker swarm init --advertise-addr ${advertise_addr}":
          path => '/bin:/usr/bin',
        }
      }
      elsif $manager_node {
        # apply exported resource to join swarm as manager
        Dockerinstall::Swarm::Node <<| title == "manager/${manager_node}" |>>
      }
    }
  }
  # need to disable manager role
  else {
    if $is_manager and $swarm['Managers'] > 2 {
      # can leave swarm if quorum remains available
      # demote manager https://docs.docker.com/engine/reference/commandline/node_demote/
      exec { "docker node demote ${nodeid}":
        path => '/bin:/usr/bin',
      }
    }
  }
}
