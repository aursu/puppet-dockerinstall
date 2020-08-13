# @summary Registry parameters
#
# Registry parameters
#
# @example
#   include dockerinstall::registry::params
class dockerinstall::registry::params {
  include tlsinfo::params
  include lsys::params

  # we use default settings defined by Docker Registry v2 project
  # it is port 5000 for registry service on localhost
  $nginx_upstream_members = {
      'localhost:5000' => {
          server => 'localhost',
          port   => 5000,
      }
  }

  # we use Docker Compose to start registry
  # Docker registyr service is Dockerinstall::Composeservice
  # resource title (<project>/<service name>)
  # <service name> is Docker compose service and must be present inside
  # docker-compose.yaml configuration file
  $compose_project = 'registry'
  $compose_service = 'registry'
  $registry_compose_service = "${compose_project}/${compose_service}"

  # data directory
  # this reflectded in docker compose file files/services/registry.yaml
  $data_directory = '/var/lib/registry'

  # Client authentication
  $internal_certdir = "${tlsinfo::params::certbase}/internal"
  $internal_cacert = "${internal_certdir}/ca.pem"
}
