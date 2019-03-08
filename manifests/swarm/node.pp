# @summary A short summary of the purpose of this defined type.
#
# A description of what this defined type does
#
# @example
#   dockerinstall::swarm::node { 'worker/sman1.domain.com': }
#   dockerinstall::swarm::node { 'manager/sman2.domain.com': }
define dockerinstall::swarm::node (
  String  $join_token,
  Optional[Stdlib::IP::Address]
          $manager_node_ip = undef,
)
{
  unless '/' in $name {
    fail('Dockerinstall::Swarm::Node must have resource title either "worker/<Node FQDN or IP>" or "manager/<Node FQDN or IP>"')
  }

  $join_ident = split($name, '/')
  $join_role = $join_ident[0]
  $join_node = $join_ident[1]

  unless $join_role in ['worker', 'manager'] {
    fail('Dockerinstall::Swarm::Node must have resource title either "worker/<Node FQDN or IP>" or "manager/<Node FQDN or IP>"')
  }

  if $join_node =~ Stdlib::Fqdn {
    unless $manager_node_ip {
      fail('IP Address must be provided either in resource $title or via $manager_node_ip parameter')
    }

    $manager_node_addr = "${manager_node_ip}:2377"
  }
  elsif $join_node =~ Stdlib::IP::Address {
    $manager_node_addr = "${join_node}:2377"
  }
  else {
    fail('Dockerinstall::Swarm::Node must have resource title either "worker/<Node FQDN or IP>" or "manager/<Node FQDN or IP>"')
  }

  exec { "docker swarm join --token ${join_token} ${manager_node_addr}":
    path => '/bin:/usr/bin',
  }
}
