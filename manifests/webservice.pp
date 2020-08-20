# A description of what this defined type does
#
# @summary A short summary of the purpose of this defined type.
#
# @example
#   dockerinstall::webservice { 'app': }
#
# @param env_name
#   Development ennvironment for which service is running (eg prod, stage, test, qa etc)
define dockerinstall::webservice (
  String  $docker_image,
  Boolean $manage_image         = false,
  String  $project_name         = $name,
  Optional[String]
          $service_name         = undef,
  Optional[String]
          $env_name             = undef,
  Optional[Hash[String, String]]
          $secrets              = undef,
  Optional[Hash[String, String]]
          $environment          = undef,
  String  $compose_file_version = '3.5',
  Enum[
    'no',
    'always',
    'on-failure'
  ]       $restart              = 'always',
  Optional[Array[String]]
          $expose_ports         = undef,
  Optional[Array[String]]
          $docker_volume        = undef,
  Optional[Array[String]]
          $docker_extra_hosts   = undef,
  Optional[Array[String]]
          $project_volumes      = undef,
  Optional[Integer]
          $docker_mtu           = undef,
  Optional[
    Hash[
      String,
      Variant[
        Dockerinstall::RLimit,
        Array[Dockerinstall::RLimit, 2]
      ]
    ]
  ]       $docker_ulimits       = undef,
  Optional[
    Array[
      Variant[
        Stdlib::IP::Address,
        Stdlib::Fqdn
      ]
    ]
  ]       $docker_dns           = undef,
  Boolean $decomission          = false,
)
{
  include dockerinstall::params
  $project_basedir   = $dockerinstall::params::compose_libdir

  if $service_name {
    $compose_service = $service_name
  }
  elsif $env_name {
    $compose_service = "${name}-${env_name}"
  }
  else {
    $compose_service = $name
  }

  $project_title     = "${project_name}/${compose_service}"

  # docker-compose project directory
  $project_directory = "${project_basedir}/${project_name}"

  # directory where project secrets are stored
  $project_secrets   = "${project_directory}/secrets"

  if $env_name and $secrets {
    if $decomission {
      file { $project_secrets:
        ensure => absent,
      }
      file { "${project_secrets}/${env_name}.env":
        ensure  => absent,
      }
    }
    else {
      file { $project_secrets:
        ensure => directory,
        mode   => '0700',
      }

      file { "${project_secrets}/${env_name}.env":
          ensure  => file,
          content => template('dockerinstall/service/secrets.env.erb'),
          notify  => Dockerservice[$project_title],
          mode    => '0600',
      }
    }
  }

  if $manage_image {
    unless $decomission {
      dockerimage { $docker_image:
        ensure => present,
        before => Dockerinstall::Composeservice[$project_title],
      }
    }
  }

  # in case if project_name is not uniq - set service configuration path to be uniq
  if $project_name == $name {
    $configuration_path = undef
  }
  else {
    $service_hash       = sha256($project_title)[0,7]
    $configuration_path = "${project_directory}/docker-compose.${service_hash}.yml"
  }

  if $decomission {
    $service_ensure = stopped
  }
  else {
    $service_ensure = running
  }

  # docker-compose service
  dockerinstall::composeservice { $project_title:
    ensure             => $service_ensure,
    project_basedir    => $project_basedir,
    configuration      => template('dockerinstall/service/service.yaml.erb'),
    configuration_path => $configuration_path,
  }
}
