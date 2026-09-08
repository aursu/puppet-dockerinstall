# Start compose service based on auto-generated compose file
#
# @summary Start compose service based on auto-generated compose file
#
# @example
#   dockerinstall::webservice { 'app': }
#
# @param docker_image
#   Specify the image to start the container from.
#   see: https://docs.docker.com/compose/compose-file/#image
#
# @param build_image
#   Whether to build docker image using docker-compose command
#
# @param manage_image
#   Whether to manage image with docker command or not
#   if set to true - will define custom resource Dockerimage for image specified
#   with parameter `docker_image`
#
# @param project_name
#   Specify an alternate project name (default: directory name)
#   see: https://docs.docker.com/compose/reference/overview/#use--p-to-specify-a-project-name
#
# @param service_name
#   Service name inside docker compose file
#   see: https://docs.docker.com/compose/compose-file/#service-configuration-reference
#
# @param env_name
#   Development environment for which service is running (eg prod, stage, test, qa etc)
#   It is mandatory for secrets setup into file secrets/<env_name>.env
#   Also it could be used for service definition as <project_name>-<env_name>
#
# @param secrets
#   Hash of environment variables to setup into environment file secrets/<env_name>.env
#   see: https://docs.docker.com/compose/compose-file/#env_file
#
# @param environment
#   Add environment variables. You can use either an array or a dictionary
#   see: https://docs.docker.com/compose/compose-file/#environment
#
# @param compose_file_version
#   Compose file versions
#   see: https://docs.docker.com/compose/compose-file/#compose-and-docker-compatibility-matrix
#
# @param restart
#   Restart policy to use for service
#   see: https://docs.docker.com/compose/compose-file/#restart
#
# @param expose_ports
#   Expose ports in short syntax
#   see: https://docs.docker.com/compose/compose-file/#ports
#
# @param docker_volume
#   Mount host paths or named volumes, specified as sub-options to a service.
#   Short syntax is supported
#   see: https://docs.docker.com/compose/compose-file/#volumes
#
# @param docker_extra_hosts
#   Add hostname mappings. Use the same values as the docker client --add-host parameter.
#   see: https://docs.docker.com/compose/compose-file/#extra_hosts
#
# @param project_volumes
#   `volumes` section allows you to create named volumes that can be reused
#   across multiple services
#   see: https://docs.docker.com/compose/compose-file/#volume-configuration-reference
#
# @param docker_mtu
#   Set the containers network MTU to specified value (for network `default`)
#   see: https://docs.docker.com/engine/reference/commandline/network_create/#bridge-driver-options
#
# @param docker_ulimits
#   Override the default ulimits for a container.
#   see: https://docs.docker.com/compose/compose-file/#ulimits
#
# @param docker_dns
#   Custom DNS servers.
#   see: https://docs.docker.com/compose/compose-file/#dns
#
# @param docker_build
#   Enable configuration options that are applied at build time.
#   see: https://docs.docker.com/compose/compose-file/#build
#
# @param docker_context
#   Either a path to a directory containing a Dockerfile, or a url to a git repository.
#   see: https://docs.docker.com/compose/compose-file/#context
#
# @param docker_file
#   Alternate Dockerfile.
#   see: https://docs.docker.com/compose/compose-file/#dockerfile
#
# @param docker_build_args
#   Add build arguments, which are environment variables accessible only during
#   the build process.
#   see: https://docs.docker.com/compose/compose-file/#args
#
# @param docker_command
#   Override the default command.
#   see: https://docs.docker.com/compose/compose-file/#command
#
# @param privileged
#   Give extended privileges to this container. A "privileged" container is given
#   access to all devices
#   see: https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities
#
# @param docker_secret
#   Array of secret names to reference in the service
#   see: https://docs.docker.com/compose/compose-file/#secrets
#
# @param project_secrets
#   Array of secret definitions (Dockerinstall::Secret struct)
#   Each secret must have: name (String), type ('file' or 'environment'), value (String)
#   Optional: setup (Boolean, default false), filename (String)
#   When setup is true and type is 'file', creates a file at ${project_directory}/secrets/filename
#   Filenames ending with .env will have .sec appended
#   see: https://docs.docker.com/compose/compose-file/#secrets-configuration-reference
#
# @param decomission
#   Compose service decomission. Takes the project down with
#   `compose down --remove-orphans`, then removes the compose configuration file
#   and the project directory, secrets included.
#
#   ⚠ This branch deliberately does **not** declare
#   `dockerinstall::composeservice`. The `dockerservice` type writes the compose
#   configuration as a *property*, so declaring the service here would rewrite the
#   file this branch removes, and the two owners would fight on every run. It is
#   also why `dockerservice`'s `stopped` is not used: `compose stop` leaves the
#   containers, the project network and the configuration in place, which is a
#   service switched off rather than one removed — its published ports return on
#   the next `up`.
#
# @param decomission_volumes
#   During decomission, also remove named volumes the project declares
#   (`compose down --volumes`). Default `false`: volume contents are not
#   recoverable, and a project's data is often the one thing worth keeping.
#
# @param decomission_image
#   During decomission, also remove the service image from the host. Requires
#   `manage_image`. Default `false`, because an image is frequently shared with
#   other projects on the same host.
#
define dockerinstall::webservice (
  String  $docker_image,
  Boolean $manage_image         = false,
  Boolean $build_image          = false,
  String  $project_name         = $name,
  Optional[String] $service_name = undef,
  Optional[String] $env_name = undef,
  Optional[Hash[String, String]] $secrets = undef,
  Optional[Hash[String, String]] $environment = undef,
  String  $compose_file_version = '3.8',
  Enum[
    'no',
    'always',
    'on-failure',
    'unless-stopped'
  ]       $restart              = 'always',
  Optional[Array[String]] $expose_ports = undef,
  Optional[Array[String]] $docker_volume = undef,
  Optional[Array[String, 1]] $docker_extra_hosts = undef,
  Optional[Array[Dockerinstall::Volume]] $project_volumes = undef,
  Optional[Integer] $docker_mtu = undef,
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
  Boolean $docker_build         = false,
  String  $docker_context       = '.',
  String  $docker_file          = 'Dockerfile',
  Optional[
    Variant[
      Hash[String, String],
      Array[String]
    ]
  ]       $docker_build_args    = undef,
  Optional[
    Variant[
      String,
      Array[String]
    ]
  ]       $docker_command       = undef,
  Boolean $privileged           = false,

  Optional[Array[String]] $docker_secret = undef,
  Optional[Array[Dockerinstall::Secret]] $project_secrets = undef,

  Boolean $decomission          = false,
  Boolean $decomission_volumes  = false,
  Boolean $decomission_image    = false,
) {
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
  $project_secrets_path   = "${project_directory}/secrets"

  # Determine if we need the secrets directory
  $need_secrets_dir = $project_secrets or ($env_name and $secrets)

  if $decomission {
    file { $project_secrets_path:
      ensure => absent,
      force  => true,
    }
  }
  elsif $need_secrets_dir {
    file { $project_secrets_path:
      ensure => directory,
      mode   => '0700',
    }
  }

  # Process project_secrets array and generate final hash for template
  if $project_secrets {
    $project_secrets_final = $project_secrets.reduce({}) |$memo, $secret| {
      $secret_name = $secret['name']
      $secret_type = $secret['type']
      $secret_value = $secret['value']
      $secret_setup = pick($secret['setup'], false)
      $filename = $secret['filename']

      # Generate secret configuration based on type
      if $secret_type == 'file' {
        # Determine the file path
        if $filename {
          # Ensure filename doesn't end with .env, if it does add .sec
          if $filename =~ /\.env$/ {
            $secret_filename = "${filename}.sec"
          } else {
            $secret_filename = $filename
          }
        } else {
          $secret_filename = "${secret_name}.sec"
        }
        $secret_file_path = "${project_secrets_path}/${secret_filename}"

        # Create file if setup is true
        if $secret_setup {
          unless $decomission {
            file { $secret_file_path:
              ensure  => file,
              content => $secret_value,
              mode    => '0600',
              owner   => $secret['uid'],
              group   => $secret['gid'],
              require => File[$project_secrets_path],
            }
          }
          $secret_config = { 'file' => "secrets/${secret_filename}" }
        }
        else {
          $secret_config = { 'file' => $secret_value }
        }
      } else {
        # type == 'environment'
        $secret_config = { 'environment' => $secret_value }
      }

      $memo + { $secret_name => $secret_config }
    }
  } else {
    $project_secrets_final = undef
  }

  if $env_name and $secrets {
    if $decomission {
      file { "${project_secrets_path}/${env_name}.env":
        ensure => absent,
      }
    }
    else {
      file { "${project_secrets_path}/${env_name}.env":
        ensure  => file,
        content => template('dockerinstall/service/secrets.env.erb'),
        notify  => Dockerservice[$project_title],
        mode    => '0600',
        require => File[$project_secrets_path],
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
    # Effective compose configuration path, mirroring what
    # dockerinstall::composeservice and the dockerservice type derive when
    # `configuration_path` is not supplied.
    $compose_file = pick($configuration_path, "${project_directory}/docker-compose.yml")

    if $decomission_volumes {
      $down_args = ['down', '--remove-orphans', '--volumes']
    }
    else {
      $down_args = ['down', '--remove-orphans']
    }

    # ⚠ `dockerservice` knows only `stopped` and `running`, and its `stop` runs
    # `compose stop` — which leaves the containers, the project network and the
    # configuration file in place. That is a service switched off, not removed:
    # its published ports come straight back on the next `up`.
    #
    # So this branch takes the project down itself, and deliberately does NOT
    # declare `dockerinstall::composeservice`. The dockerservice type writes the
    # compose configuration as a *property*, so declaring the service here would
    # rewrite the very file this branch removes and the two would fight on every
    # run — the same resource under two owners with opposite intent.
    exec { "compose-down-${project_title}":
      command  => "docker compose -f ${compose_file} -p ${project_name} ${join($down_args, ' ')}",
      onlyif   => "test -f ${compose_file}",
      path     => ['/usr/local/sbin', '/usr/local/bin', '/usr/sbin', '/usr/bin', '/sbin', '/bin'],
      provider => shell,
      before   => File[$compose_file],
    }

    # Order matters: `compose down` needs the file to identify what it is tearing
    # down, so the file goes only after the project is down.
    file { $compose_file:
      ensure => absent,
    }

    file { $project_directory:
      ensure  => absent,
      force   => true,
      require => File[$compose_file],
    }

    if $manage_image and $decomission_image {
      dockerimage { $docker_image:
        ensure  => absent,
        require => File[$project_directory],
      }
    }
  }
  else {
    # docker-compose service
    dockerinstall::composeservice { $project_title:
      ensure             => running,
      project_basedir    => $project_basedir,
      configuration      => template('dockerinstall/service/service.yaml.erb'),
      configuration_path => $configuration_path,
      build_image        => $build_image,
    }
  }
}
