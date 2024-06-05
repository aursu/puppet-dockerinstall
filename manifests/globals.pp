# @summary Module global settings
#
# Module global settings
#
# @example
#   include dockerinstall::globals
class dockerinstall::globals (
  String $compose_download_source = $dockerinstall::params::compose_download_source,
  Optional[String] $compose_version = $dockerinstall::compose_version,
) inherits dockerinstall::params {
  # we allow user to not care about compose version and keep it default
  # (specified in params)
  # $compose_download_version - either user specified or default
  if $compose_version {
    $compose_download_version = $compose_version
  }
  else {
    $compose_download_version = $dockerinstall::params::compose_version
  }

  # in URL base folder lcated Docker Compose binary and checksum
  if versioncmp($compose_download_version, '2.0.0') >= 0 {
    $compose_download_name    = $dockerinstall::params::composev2_download_name
    $compose_download_urlbase = "${compose_download_source}/v${compose_download_version}"
    $install_plugin           = true
  }
  else {
    $compose_download_name    = $dockerinstall::params::compose_download_name
    $compose_download_urlbase = "${compose_download_source}/${compose_download_version}"
    $install_plugin           = false
  }
  $compose_checksum_name      = "${compose_download_name}.sha256"

  if $facts['os']['family'] == 'windows' {
    if $facts['docker_user_home'] {
      $docker_user_home = $facts['docker_user_home']
      $docker_user_dir = "${$docker_user_home}\\.docker"
    }
    elsif $facts['docker_user_dir_path'] {
      $docker_user_dir = $facts['docker_user_dir_path']
    }
    elsif $facts['docker_username'] {
      $docker_username = $facts['docker_username']
      $docker_user_dir = "C:\\Users\\${docker_username}\\.docker"
    }
    else {
      $docker_user_dir = undef
    }

    if $docker_user_dir {
      $docker_user_certdir = "${docker_user_dir}\\certs.d"
    }
    else {
      $docker_user_certdir = undef
    }
  }
  else {
    if $facts['docker_user_home'] {
      $docker_user_home = $facts['docker_user_home']
      $docker_user_dir = "${$docker_user_home}/.docker"
    }
    elsif $facts['identity']['user'] == 'root' {
      $docker_user_dir = '/root/.docker'
    }
    elsif $facts['identity']['user'] {
      $docker_username = $facts['identity']['user']
      $docker_user_dir = "/home/${docker_username}/.docker"
    }
    else {
      $docker_user_dir = undef
    }

    if $docker_user_dir {
      $docker_user_certdir = "${docker_user_dir}/certs.d"
    }
    else {
      $docker_user_certdir = undef
    }
  }
}
