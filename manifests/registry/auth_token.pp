# @summary Enable integration of Registry into GitLab authentication mechanism
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
# @param realm_host
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
          $realm_host           = undef,
  Optional[Stdlib::HTTPUrl]
          $realm                = undef,
  Optional[String]
          $realm_certificate    = undef,
  String  $service              = $dockerinstall::registry::params::auth_token_service,
  String  $issuer               = $dockerinstall::registry::params::auth_token_issuer,
  Boolean $registry_cert_export = true,
  Boolean $token_map_export     = true,
) inherits dockerinstall::registry::params {
  include dockerinstall::registry::setup::token

  # auth:
  #   token:
  #     realm: https://gitlab1.domain.tld/jwt/auth
  #     service: container_registry
  #     issuer: omnibus-gitlab-issuer
  #     rootcertbundle: /var/opt/gitlab/registry/gitlab-registry.crt
  #     autoredirect: false

  $rootcertbundle = $dockerinstall::registry::params::auth_token_rootcertbundle

  if $enable {
    if $gitlab {
      unless $realm_host {
        fail('You must supply realm_host parameter to dockerinstall::registry::auth_token (which is GitLab server name)')
      }

      $token_realm = "https://${realm_host}/jwt/auth"

      if $registry_cert_export {
        # export certificate from GitLab host realm_host
        File <<| title == 'registry_rootcertbundle' and tag == $realm_host |>>
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

      file { 'registry_rootcertbundle':
        path    => $rootcertbundle,
        content => $realm_certificate,
      }
    }

    if $token_map_export {
      File <<| title == 'registry_tokens_map' and tag == $realm_host |>>
    }
  }
}
