# @summary Enable integration of Registry into GitLab authentication
#
# Enable integration of Registry into GitLab authentication
# see https://docs.gitlab.com/ee/administration/packages/container_registry.html#enable-the-container-registry
#
# @example
#   include dockerinstall::registry::auth_token
#
# @param enable
#   Whether to enable token authentication or not
#
# @param gitlab
#   Whether to enable GitLab as token provider or not
#
# @param gitlab_host
#   If GitLab is in use as token provider than GitLab host must be provided
#
# @param realm
#   The realm in which the registry server authenticates
#   eg https://gitlab.domain.tld/jwt/auth
#
# @param realm_certificate
#   Contents of the certificate that Realm (eg GitLab) uses to sign the tokens.
#
# @param rootcertbundle
#   The absolute path to the root certificate bundle. This bundle contains the
#   public part of the certificates used to sign authentication tokens.
#
# @param service
#   The service being authenticated.
#
# @param issuer
#   The name of the token issuer. The issuer inserts this into the token so it
#   must match the value configured for the issuer.
#
# @param registry_cert_export
#   Whether to import token certificate from PuppetDB or not. If set to false
#   than token certificate should be provide either via `realm_certificate` or
#   it must be set via classes `gitlabinstall::gitlab` or
#   `dockerinstall::registry::gitlab`
#
class dockerinstall::registry::auth_token (
  Boolean $enable               = false,
  Boolean $gitlab               = false,
  Optional[Stdlib::Fqdn]
          $gitlab_host          = undef,
  Optional[Stdlib::HTTPUrl]
          $realm                = undef,
  Optional[String]
          $realm_certificate    = undef,
  String  $service              = $dockerinstall::registry::params::auth_token_service,
  String  $issuer               = $dockerinstall::registry::params::auth_token_issuer,
  Boolean $registry_cert_export = true,
) inherits dockerinstall::registry::params
{
  # auth:
  #   token:
  #     realm: https://gitlab1.domain.tld/jwt/auth
  #     service: container_registry
  #     issuer: omnibus-gitlab-issuer
  #     rootcertbundle: /var/opt/gitlab/registry/gitlab-registry.crt
  #     autoredirect: false

  $rootcertbundle = $dockerinstall::registry::params::auth_token_rootcertbundle
  $tokenbundle_certdir = $dockerinstall::registry::params::tokenbundle_certdir

  if $enable {
    if $gitlab {
      unless $gitlab_host {
        fail('You must supply gitlab_host parameter to dockerinstall::registry::auth_token')
      }

      $token_realm = "https://${gitlab_host}/jwt/auth"

      if $registry_cert_export {
        file { $tokenbundle_certdir:
          ensure => directory,
        }

        # export certificate from GitLab host gitlab_host
        File <<| title == 'registry_rootcertbundle' and tag == $gitlab_host |>>
      }
    }
    else {
      unless $realm {
        fail('You must supply auth_token_realm parameter to dockerinstall::registry::auth_token')
      }
      unless $realm_certificate {
        fail('You must supply realm_certificate parameter to dockerinstall::registry::auth_token')
      }

      $token_realm = $realm

      # create certificate directory before creating certificate itself
      file { $tokenbundle_certdir:
        ensure => directory,
      }

      file { 'registry_rootcertbundle':
        path    => $rootcertbundle,
        content => $realm_certificate,
      }
    }
  }
}
