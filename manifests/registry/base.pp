# @summary Run registry container
#
# Run registry container
#
# @example
#   include dockerinstall::registry::base
class dockerinstall::registry::base (
    String  $docker_image   = 'registry:2.7.1',
    Stdlib::Unixpath
            $data_directory = $dockerinstall::registry::params::data_directory,
) inherits dockerinstall::registry::params
{
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
    },
    docker_volume => [
      "${data_directory}:/var/lib/registry",
    ]
  }
}
