# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include dockerinstall::compose
class dockerinstall::compose (
    Optional[String]
            $version          = $dockerinstall::compose_version,
    String  $download_source  = $dockerinstall::params::compose_download_source,
    String  $download_name    = $dockerinstall::params::compose_download_name,
    String  $checksum_name    = $dockerinstall::params::compose_checksum_name,
    String  $checksum_command = $dockerinstall::params::compose_checksum_command,
    Stdlib::Absolutepath
            $tmpdir           = $dockerinstall::params::download_tmpdir,
    Stdlib::Absolutepath
            $binary_path      = $dockerinstall::params::compose_binary_path,
    Stdlib::Absolutepath
            $rundir           = $dockerinstall::params::compose_rundir,
) inherits dockerinstall::params
{
    Exec {
        path => '/bin:/usr/bin',
        cwd  => $tmpdir,
    }

    # we allow user to not care about compose version and keep it default
    # (specified in params)
    # $download_version - either user specified or default
    if $version {
        $download_version = $version
    }
    else {
        $download_version = $dockerinstall::params::compose_version
    }

    # in URL base folder lcated Docker Compose binary and checksum
    $download_url_base = "${download_source}/${download_version}"

    # we store all checksum files in temporary folder, therefore add suffix to
    # not overwrite
    $checksum_version_name = "${checksum_name}.${download_version}"
    $checksum_download_path = "${tmpdir}/${checksum_version_name}"

    # download checksm file into temporary directory
    exec { "curl -L ${download_url_base}/${checksum_name} -o ${checksum_version_name}":
        creates => $checksum_download_path,
        alias   => 'docker-compose-checksum',
    }

    # download binary if checksum not match
    exec { "curl -L ${download_url_base}/${download_name} -o ${download_name}":
        unless  => "${checksum_command} -c ${checksum_version_name}",
        require => Exec['docker-compose-checksum'],
        alias   => 'docker-compose-download',
    }

    # install binary into specified location (by default is
    # /usr/local/bin/docker-compose)
    file { $binary_path:
        ensure    => file,
        source    => "file://${tmpdir}/${download_name}",
        mode      => '0755',
        owner     => 'root',
        group     => 'root',
        subscribe => Exec['docker-compose-download'],
        alias     => 'docker-compose',
    }

    file { $rundir:
        ensure => directory,
        mode   => '0755',
        force  => true,
    }
}
