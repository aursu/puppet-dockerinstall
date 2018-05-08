# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include dockerinstall::params
class dockerinstall::params {
    $compose_version          = '1.21.2'
    $compose_download_source  = 'https://github.com/docker/compose/releases/download'

    # docker compose project provides binaries only for x86_64 architecture
    # for Windows, Linux and Darwin
    # see https://github.com/docker/compose/releases
    $compose_download_name    = 'docker-compose-Linux-x86_64'
    $compose_checksum_name    = "${compose_download_name}.sha256"
    $compose_checksum_command = 'sha256sum'
    $download_tmpdir          = '/tmp'
    $compose_binary_path      = '/usr/local/bin/docker-compose'
}
