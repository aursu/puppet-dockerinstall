# @summary Run registry container
#
# Run registry container
#
# @example
#   include dockerinstall::registry::base
class dockerinstall::registry::base (
    String  $docker_image   = 'registry:2.8.1',
    Stdlib::Unixpath
            $data_directory = $dockerinstall::registry::params::data_directory,
) inherits dockerinstall::registry::params {
  include dockerinstall::registry::auth_token
  $rootcertbundle = $dockerinstall::registry::auth_token::rootcertbundle

  # auth:
  #   token:
  #     realm: https://gitlab1.domain.tld/jwt/auth
  #     service: container_registry
  #     issuer: omnibus-gitlab-issuer
  #     rootcertbundle: /var/opt/gitlab/registry/gitlab-registry.crt
  #     autoredirect: false

  $auth_token_enable = $dockerinstall::registry::auth_token::enable
  if $auth_token_enable {
    $auth_tonken_environment = {
      'REGISTRY_AUTH_TOKEN_REALM'          => $dockerinstall::registry::auth_token::token_realm,
      'REGISTRY_AUTH_TOKEN_SERVICE'        => $dockerinstall::registry::auth_token::service,
      'REGISTRY_AUTH_TOKEN_ISSUER'         => $dockerinstall::registry::auth_token::issuer,
      'REGISTRY_AUTH_TOKEN_ROOTCERTBUNDLE' => $rootcertbundle,
      'REGISTRY_AUTH_TOKEN_AUTOREDIRECT'   => 'false'
    }

    $auth_token_volume = [
      "${rootcertbundle}:${rootcertbundle}"
    ]
  }
  else {
    $auth_tonken_environment = {}
    $auth_token_volume = []
  }

  $compose_service = $dockerinstall::registry::params::compose_service
  $compose_project = $dockerinstall::registry::params::compose_project

  # According to documentaton https://docs.docker.com/registry/deploying/
  # we use registry:2 image from docker.io/library repository
  dockerinstall::webservice { $compose_project:
    service_name  => $compose_service,
    manage_image  => true,
    docker_image  => $docker_image,
    expose_ports  => [
      '5000:5000',
    ],
    environment   => {
                        'REGISTRY_STORAGE_DELETE_ENABLED' => 'true',
                      } +
                      $auth_tonken_environment,
    docker_volume => [
                        "${data_directory}:/var/lib/registry",
                      ] +
                      $auth_token_volume,
  }

  # Read only mode environment:
  # REGISTRY_STORAGE_MAINTENANCE_READOLY: "{\"enabled\": \"true\"}"

  # garbage collector
  # gc:
  #   image: registry:2.7.1
  #   volumes:
  #     - /var/lib/registry:/var/lib/registry
  #   entrypoint: [ "/bin/registry" ]
  #   command: ["garbage-collect", "/etc/docker/registry/config.yml"]
}
