# @summary Export GitLab certificate and tokens map for Registry authentication
#
# Export GitLab certificate and tokens map for Registry authentication
#
# @example
#   include dockerinstall::registry::gitlab
#
# @param registry_cert_export
#   Whether to write certificate content into local file system or export it to
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
# @param token_map_export
#   Whether to export Nginx tokens map into PuppetDB or not
#
# @param token_map_setup
#   Whether to setup Nginx tokens map locally or not (mutually exclusive with
#   `token_map_export` with lower priority)
#
# @param nginx_tokens_map
#   Path to Nginx config which represents map of tokenns to project. This config file
#   is used in `include` directive for map $uri $gitlab_token {} configuration
#   directive. See http://nginx.org/en/docs/http/ngx_http_map_module.html#map
#   Default is /etc/nginx/conf.d/mapping/gitlab-auth-token.conf
#
class dockerinstall::registry::gitlab (
  Boolean $registry_cert_export = true,
  Optional[String] $registry_internal_certificate = undef,
  Boolean $token_map_export = true,
  Boolean $token_map_setup = true,
  Stdlib::Unixpath $nginx_tokens_map = $dockerinstall::registry::params::nginx_tokens_map,
  Optional[Stdlib::Fqdn] $gitlab_host = $dockerinstall::params::certname,
) inherits dockerinstall::registry::params {
  include dockerinstall::registry::setup::token

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
    file { $registry_cert_path:
      content => $registry_cert_content,
    }
  }

  $gitlab_tokens = $facts['gitlab_auth_token']
  if $token_map_export {
    @@file { 'registry_tokens_map':
      ensure  => file,
      path    => $nginx_tokens_map,
      content => template('dockerinstall/registry/nginx/mapping/gitlab-auth-token.conf.erb'),
      tag     => $gitlab_host,
    }
  }
  elsif $token_map_setup {
    file { $nginx_tokens_map:
      ensure  => file,
      content => template('dockerinstall/registry/nginx/mapping/gitlab-auth-token.conf.erb'),
    }
  }
}
