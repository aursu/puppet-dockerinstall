# @summary A short summary of the purpose of this defined type.
#
# A description of what this defined type does
#
# @example
#   dockerinstall::swarm::promote { 'namevar': }
define dockerinstall::swarm::promote (
  String $nodeid = $name,
) {
  # promote: https://docs.docker.com/engine/reference/commandline/node_promote/
  exec { "docker node promote ${nodeid}":
    path => '/bin:/usr/bin',
  }
}
