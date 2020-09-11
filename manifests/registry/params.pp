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
  $compose_service_title = "${compose_project}/${compose_service}"

  # data directory
  # this reflectded in docker compose file files/services/registry.yaml
  $data_directory = '/var/lib/registry'

  # Client authentication
  $internal_certdir = "${tlsinfo::params::certbase}/internal"
  $internal_cacert = "${internal_certdir}/ca.pem"

  $gitlab_registry_key_path = '/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key'

  # The service being authenticated.
  $auth_token_service = 'container_registry'

  # The name of the token issuer. The issuer inserts this into the token so it
  # must match the value configured for the issuer.
  $auth_token_issuer = 'omnibus-gitlab-issuer'

  # The absolute path to the root certificate bundle. This bundle contains the
  # public part of the certificates used to sign authentication tokens.
  $auth_token_rootcertbundle = '/etc/docker/registry/tokenbundle.pem'

  # When set to `true`, `realm` will automatically be set using the Host header
  # of the request as the domain and a path of `/auth/token/`
  $auth_token_autoredirect = false
}
