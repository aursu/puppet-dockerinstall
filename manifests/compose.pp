# Docker Compose installation
#
# @summary Docker Compose installation
#
# @example
#   include dockerinstall::compose
class dockerinstall::compose (
    String  $download_name    = $dockerinstall::globals::compose_download_name,
    String  $checksum_name    = $dockerinstall::globals::compose_checksum_name,
    String  $checksum_command = $dockerinstall::params::compose_checksum_command,
    Stdlib::Absolutepath
            $tmpdir           = $dockerinstall::params::download_tmpdir,
    Stdlib::Absolutepath
            $binary_path      = $dockerinstall::params::compose_binary_path,
    Stdlib::Absolutepath
            $rundir           = $dockerinstall::params::compose_rundir,
    Stdlib::Absolutepath
            $libdir           = $dockerinstall::params::compose_libdir,
    String  $binary_ensure    = 'file',
) inherits dockerinstall::globals
{
    $download_version  = $dockerinstall::globals::compose_download_version

    # in URL base folder located Docker Compose binary and checksum
    $download_url_base = $dockerinstall::globals::compose_download_urlbase

    # we store all checksum files in temporary folder, therefore add suffix to
    # not overwrite
    $checksum_version_name = "${checksum_name}.${download_version}"
    $checksum_download_path = "${tmpdir}/${checksum_version_name}"

    if $binary_ensure == 'file' {
      exec {
        default:
          path => '/bin:/usr/bin',
          cwd  => $tmpdir,
        ;
        # download checksm file into temporary directory
        'docker-compose-checksum':
          command => "curl -L ${download_url_base}/${checksum_name} -o ${checksum_version_name}",
          # creates => $checksum_download_path,
          unless  => "grep ${download_name} ${checksum_download_path}",
        ;
        # download binary if checksum not match
        'docker-compose-download':
          command => "curl -L ${download_url_base}/${download_name} -o ${download_name}",
          unless  => "${checksum_command} -c ${checksum_version_name}",
          require => Exec['docker-compose-checksum'],
          notify  => File[$binary_path],
        ;
      }

      $compose_setup = {
        source => "file://${tmpdir}/${download_name}",
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
      }
    }
    else {
      $compose_setup = {}
    }

    # install binary into specified location (by default is
    # /usr/local/bin/docker-compose)
    file { 'docker-compose':
      *      => $compose_setup,
      ensure => $binary_ensure,
      path   => $binary_path,
    }

    file { [$rundir, $libdir]:
        ensure => directory,
        mode   => '0755',
        force  => true,
    }
}
