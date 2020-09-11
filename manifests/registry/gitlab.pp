# @summary Export GitLab certificate for Registry authentication
#
# Export GitLab certificate for Registry authentication
#
# @example
#   include dockerinstall::registry::gitlab
#
# @param registry_cert_export
#   Whether to write certificate content intoo local file system or export it to
#   Puppet DB
#
# @param registry_internal_certificate
#   Contents of the certificate that GitLab uses to sign the tokens. This
#   parameter allows to setup custom certificate into file system path
#   (`registry_cert_path`) or export to Puppet DB.
#
# @param registry_cert_path
#   This is the path where `registry_internal_certificate` contents will be
#   written to disk.
#   default certificate location is /etc/docker/registry/tokenbundle.pem
#
class dockerinstall::registry::gitlab (
  Boolean $registry_cert_export          = true,
  Optional[String]
          $registry_internal_certificate = undef,
  Optional[Stdlib::Fqdn]
          $gitlab_host                   = $dockerinstall::params::certname,
) inherits dockerinstall::registry::params
{
  $tokenbundle_certdir = $dockerinstall::registry::params::tokenbundle_certdir
  $registry_cert_path  = $dockerinstall::registry::params::auth_token_rootcertbundle

  $registry_cert_content = $registry_internal_certificate ? {
    String  => $registry_internal_certificate,
    default => $facts['puppet_sslcert']['hostcert']['data'],
  }

  if $registry_cert_export {
    @@file { 'registry_rootcertbundle':
      path    => $registry_cert_path,
      content => $registry_cert_content,
      tag     => $gitlab_host,
    }
  }
  else {
    file { $tokenbundle_certdir:
      ensure => directory,
    }

    file { $registry_cert_path:
      content => $registry_cert_content,
    }
  }
}
