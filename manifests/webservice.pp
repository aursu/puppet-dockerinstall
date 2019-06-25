# @summary A short summary of the purpose of this defined type.
#
# A description of what this defined type does
#
# @example
#   dockerinstall::webservice { 'namevar': }
define dockerinstall::webservice (
  String  $docker_image,
  Optional[Stdlib::Unixpath]
          $app_root           = undef,
  Optional[Array[String]]
          $docker_volume      = undef,
  Optional[Array[String]]
          $docker_extra_hosts = undef,
  Optional[Integer]
          $docker_mtu         = undef,
) {
}
