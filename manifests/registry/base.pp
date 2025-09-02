# @summary Run registry container
#
# Run registry container
#
# @param docker_image
#   Docker image to use for the registry container. Defaults to 'registry:3.0.0'
#
# @param data_directory
#   Path to the directory where registry data will be stored on the host system.
#   This directory will be mounted as /var/lib/registry inside the container.
#
# @param accesslog_disabled
#   Boolean flag to disable access logging in the registry.
#   When set to true, sets REGISTRY_LOG_ACCESSLOG_DISABLED=true environment variable.
#
# @param traces_disabled
#   Boolean flag to disable OpenTelemetry traces in the registry.
#   When set to true, sets OTEL_TRACES_EXPORTER=none environment variable.
#
# @example
#   include dockerinstall::registry::base
class dockerinstall::registry::base (
  String $docker_image = 'registry:3.0.0',
  Stdlib::Unixpath $data_directory = $dockerinstall::registry::params::data_directory,
  Boolean $accesslog_disabled = false,
  Boolean $traces_disabled = false,
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
      'REGISTRY_AUTH_TOKEN_AUTOREDIRECT'   => 'false',
    }

    $auth_token_volume = [
      "${rootcertbundle}:${rootcertbundle}",
    ]
  }
  else {
    $auth_tonken_environment = {}
    $auth_token_volume = []
  }

  if $accesslog_disabled {
    $accesslog_disabled_environment = {
      'REGISTRY_LOG_ACCESSLOG_DISABLED' => 'true',
    }
  }
  else {
    $accesslog_disabled_environment = {}
  }

  if $traces_disabled {
    $traces_disabled_environment = {
      'OTEL_TRACES_EXPORTER' => 'none',
    }
  }
  else {
    $traces_disabled_environment = {}
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
    # Use the delete structure to enable the deletion of image blobs and manifests by digest
    environment   => {
      'REGISTRY_STORAGE_DELETE_ENABLED' => 'true',
    } +
    $auth_tonken_environment +
    $accesslog_disabled_environment +
    $traces_disabled_environment,
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
