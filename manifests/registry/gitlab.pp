# @summary Export GitLab certificate for Registry authentication
#
# Export GitLab certificate for Registry authentication
#
# @example
#   include dockerinstall::registry::gitlab
#
# @param registry_internal_key
#   Contents of the key that GitLab uses to sign the tokens.
#   A certificate-key pair is required for GitLab and the external container
#   registry to communicate securely. You will need to create a certificate-key
#   pair, configuring the external container registry with the public certificate
#   and configuring GitLab with the private key
#
# @param registry_key_path
#   Path to the key that matches the certificate on the Registry side.
#   If no file is specified, Omnibus GitLab will default it to
#   `/var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key` and will populate it.
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
  Optional[String]
          $registry_internal_key         = undef,
  Optional[Stdlib::Unixpath]
          $registry_key_path             = $dockerinstall::registry::params::gitlab_registry_key_path,
  Boolean $registry_cert_export          = true,
  Optional[String]
          $registry_internal_certificate = undef,
  Optional[Stdlib::Unixpath]
          $registry_cert_path            = $dockerinstall::registry::params::auth_token_rootcertbundle,
  Optional[Stdlib::Fqdn]
          $gitlab_host                   = $dockerinstall::params::certname,
) inherits dockerinstall::registry::params
{
  include dockerinstall::params
  $hostprivkey = $dockerinstall::params::hostprivkey

  if $registry_internal_key {
    file { $registry_key_path:
      content => $registry_internal_key,
    }
  }
  else {
    file { $registry_key_path:
      source  => "file://${hostprivkey}",
    }
  }

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
    file { $registry_cert_path:
      content => $registry_cert_content,
    }
  }
}
