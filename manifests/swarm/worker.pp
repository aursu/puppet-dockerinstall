# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include dockerinstall::swarm::worker
class dockerinstall::swarm::worker (
  Boolean $enable = true,
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

  $is_worker     = ! $is_manager

  $node_name = $::fqdn
  $nodeid = $swarm['NodeID']

  if $enable {
    if $swarm_enabled {
      if $is_manager {
        # demote manager https://docs.docker.com/engine/reference/commandline/node_demote/
        exec { "docker node demote ${nodeid}":
          path => '/bin:/usr/bin',
        }
      }
    }
    else {
      if $manager_node {
        # apply exported resource to join swarm as worker
        Dockerinstall::Swarm::Node <<| title == "worker/${manager_node}" |>>
      }
    }
  }
  # need to disable worker role (leave swarm)
  elsif $swarm_enabled {
    # can leave swarm if quorum remains available
    # or if node is worker
    if ($is_manager and $swarm['Managers'] > 2) or $is_worker {
      # check if it is allowed to leave swarm
      exec { "docker swarm leave --force":
        path => '/bin:/usr/bin',
      }
    }
  }
}
