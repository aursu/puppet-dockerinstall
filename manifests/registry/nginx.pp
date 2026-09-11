# @summary Registry Nginx setup
#
# Registry Nginx setup
#
# @param server_name
#   Virtual host name nginx serves the registry under.
#
# @param ssl
#   Whether to serve the registry over HTTPS.
#
# @param ssl_cert
#   Path to the server certificate. Required when `ssl` is true.
#
# @param ssl_key
#   Path to the server private key. Required when `ssl` is true.
#
# @param ssl_client_ca_auth
#   Whether to require a client certificate (mutual TLS) from registry clients.
#
# @param manage_nginx_core
#   Whether this class manages nginx itself. Set false where another profile on
#   the host already owns nginx core, and declare `class nginx` there.
#
# @param manage_web_user
#   Whether to manage the web server user and group.
#
# @param manage_document_root
#   Whether to manage the document root directory.
#
# @param global_ssl_redirect
#   Whether to redirect plain HTTP to HTTPS for this virtual host.
#
# @param nginx_tokens_map
#   Path to the nginx map file used for registry auth token handling.
#
# @param upstream_host
#   Host nginx proxies to for the registry itself. Default `localhost`, which is
#   correct while the registry publishes its port on every interface or on
#   loopback.
#
#   ⚠ **Set this whenever `dockerinstall::registry::base::listen_ip` names a
#   specific non-loopback address.** The two belong together: binding the
#   container to an internal address while nginx still proxies to `localhost`
#   leaves nginx unable to reach it, and **every pull through the registry fails
#   with 502 Bad Gateway** — measured on a live registry on 2026-09-09. The
#   registry's own error log names the upstream it could not reach, which is the
#   quickest way to recognise it.
#
#   Loopback needs no change here; a specific address does.
#
# @example
#   include dockerinstall::registry::nginx
#
# @example Registry bound to an internal address rather than loopback
#   class { 'dockerinstall::registry::base':
#     listen_ip => '10.0.0.10',
#   }
#   class { 'dockerinstall::registry::nginx':
#     server_name   => 'registry.example.com',
#     upstream_host => '10.0.0.10',
#   }
class dockerinstall::registry::nginx (
  String $server_name,
  Stdlib::Host $upstream_host = 'localhost',
  Boolean $ssl = false,
  Optional[String] $ssl_cert = undef,
  Optional[String] $ssl_key = undef,
  Boolean $ssl_client_ca_auth = false,

  Boolean $manage_nginx_core = true,
  Boolean $manage_web_user = true,
  Boolean $manage_document_root = true,
  Boolean $global_ssl_redirect = true,
  Stdlib::Unixpath $nginx_tokens_map = $dockerinstall::registry::params::nginx_tokens_map,
) inherits dockerinstall::registry::params {
  include dockerinstall::registry::auth_token

  $auth_token_enable = $dockerinstall::registry::auth_token::enable

  # Built from upstream_host rather than taken from params, so the address nginx
  # proxies to can follow the address the registry container is bound to. The
  # port is fixed at 5000 because dockerinstall::registry::base publishes the
  # container's 5000 regardless of which host address it binds.
  $nginx_upstream_members = {
    "${upstream_host}:5000" => {
      server => $upstream_host,
      port   => 5000,
    },
  }
  $internal_cacert        = $dockerinstall::registry::params::internal_cacert

  $user_home              = $lsys_nginx::params::user_home
  $document_root          = "${user_home}/html"
  $daemon_user            = $bsys::webserver::params::user
  $daemon_group           = $bsys::webserver::params::group

  # if SSL enabled - both certificate and key must be provided
  if $ssl and !($ssl_cert and $ssl_key) {
    fail('SSL certificate path and/or SSL private key path not provided')
  }

  # Token based authentication
  if $auth_token_enable {
    $auth_token_prepend = [
      template('dockerinstall/registry/nginx/chunks/registry-auth.conf.erb'),
    ]
  }
  else {
    $auth_token_prepend = []
  }

  if $manage_nginx_core {
    class { 'lsys_nginx':
      manage_user          => $manage_web_user,
      manage_document_root => $manage_document_root,
      global_ssl_redirect  => $global_ssl_redirect,
      manage_map_dir       => true,
      http_raw_prepend     => [
        # Set a variable to help us decide if we need to add the
        # 'Docker-Distribution-Api-Version' header.
        # The registry always sets this header.
        # In the case of nginx performing auth, the header is unset
        # since nginx is auth-ing before proxying.
        file('dockerinstall/registry/nginx/chunks/dont-duplicate-registry-header.conf'),
      ] +
      $auth_token_prepend,
    }
  }
  else {
    nginx::resource::config { '98-registry-header':
      content => file('dockerinstall/registry/nginx/chunks/dont-duplicate-registry-header.conf'),
    }

    if $manage_document_root {
      file { $document_root:
        ensure => directory,
        owner  => $daemon_user,
        group  => $daemon_group,
      }
    }

    if $auth_token_enable {
      nginx::resource::config { '99-registry-auth':
        content => template('dockerinstall/registry/nginx/chunks/registry-auth.conf.erb'),
      }
    }
  }

  # Nginx upstream for GitLab Workhorse socket
  nginx::resource::upstream { 'docker-registry':
    members => $nginx_upstream_members,
  }

  # lint:ignore:140chars
  # type=AVC msg=audit(1554992273.902:517150): avc:  denied  { name_connect } for  pid=2581 comm="nginx" dest=5000 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:commplex_main_port_t:s0 tclass=tcp_socket permissive=0
  # lint:endignore
  # Was caused by:
  # The boolean httpd_can_network_connect was set incorrectly.
  # Description:
  # Allow httpd to can network connect
  # Allow access by executing:
  # setsebool -P httpd_can_network_connect 1
  if $facts['os']['selinux']['enabled'] {
    selinux::boolean { 'httpd_can_network_connect': }
  }

  # if SSL enabled - use SSL only
  if $ssl {
    $listen_port = 443
  }
  else {
    $listen_port = 80
  }

  if $auth_token_enable {
    $ssl_client_cert = $internal_cacert
    # rule to deny non-authenticated users
    $ssl_client_check = [
      file('dockerinstall/registry/nginx/chunks/enable-client-auth-token.conf'),
    ]
    $auth_proxy_header = [
      'Authorization     $proxy_authorization',
    ]
  }
  # SSL/TLS client certificates auth only
  elsif $ssl_client_ca_auth {
    $ssl_client_cert = $internal_cacert
    # rule to deny non-authenticated users
    $ssl_client_check = [
      file('dockerinstall/registry/nginx/chunks/enable-client-auth.conf'),
    ]
    $auth_proxy_header = []
  }
  else {
    $ssl_client_cert = undef
    $ssl_client_check = []
    $auth_proxy_header = []
  }

  # default document root
  file { "${document_root}/registry-denied.json":
    content => file('dockerinstall/registry/registry-denied.json'),
    owner   => $daemon_user,
  }

  # setup GitLab nginx main config
  # https://docs.docker.com/registry/recipes/nginx/
  nginx::resource::server { 'registry-http':
    ssl                       => $ssl,
    http2                     => $ssl,
    ssl_cert                  => $ssl_cert,
    ssl_key                   => $ssl_key,
    ssl_session_timeout       => '1d',
    ssl_cache                 => 'shared:SSL:50m',
    ssl_session_tickets       => false,
    ssl_protocols             => 'TLSv1.2 TLSv1.3',
    ssl_ciphers               => 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305', # lint:ignore:140chars
    ssl_ecdh_curve            => 'X25519:prime256v1:secp384r1',
    ssl_stapling              => true,
    ssl_stapling_verify       => true,
    ssl_client_cert           => $ssl_client_cert,
    ssl_verify_client         => 'optional',
    listen_ip                 => '*',
    listen_port               => $listen_port,
    server_name               => [
      $server_name,
    ],

    # disable any limits to avoid HTTP 413 for large image uploads
    client_max_body_size      => 0,

    # required to avoid HTTP 411: see Issue #1486 (https://github.com/moby/moby/issues/1486)
    chunked_transfer_encoding => true,

    # HSTS Config
    # https://www.nginx.com/blog/http-strict-transport-security-hsts-and-nginx/
    add_header                => {
      'Strict-Transport-Security' => 'max-age=15768000',
    },
    # Individual nginx logs for this GitLab vhost
    access_log                => '/var/log/nginx/registry_access.log',
    format_log                => 'combined',
    error_log                 => '/var/log/nginx/registry_error.log',
    error_pages               => {
      403 => '/registry-denied.json',
    },
    locations                 => {
      # added location for exect /v2/ request
      '= /v2/'                => {
        raw_prepend        => [
          file('dockerinstall/registry/nginx/chunks/restrict-old-docker-access.conf'),
        ],
        add_header         => {
          # If $docker_distribution_api_version is empty, the header is not added.
          # See the map directive above where this variable is defined.
          'Docker-Distribution-Api-Version' => { '$docker_distribution_api_version' => 'always' },
        },
        proxy              => 'http://docker-registry',
        proxy_set_header   => [
          # required for docker client's sake
          'Host              $http_host',
          # pass on real client's IP
          'X-Real-IP         $remote_addr',
          'X-Forwarded-For   $proxy_add_x_forwarded_for',
          'X-Forwarded-Proto $scheme',
        ] +
        $auth_proxy_header,
        proxy_read_timeout => 900,
      },
      '/v2/'                  => {
        raw_prepend        => [
          file('dockerinstall/registry/nginx/chunks/restrict-old-docker-access.conf'),
        ] +
        $ssl_client_check,
        add_header         => {
          # If $docker_distribution_api_version is empty, the header is not added.
          # See the map directive above where this variable is defined.
          'Docker-Distribution-Api-Version' => { '$docker_distribution_api_version' => 'always' },
        },
        proxy              => 'http://docker-registry',
        proxy_set_header   => [
          # required for docker client's sake
          'Host              $http_host',
          # pass on real client's IP
          'X-Real-IP         $remote_addr',
          'X-Forwarded-For   $proxy_add_x_forwarded_for',
          'X-Forwarded-Proto $scheme',
        ] +
        $auth_proxy_header,
        proxy_read_timeout => 900,
      },
      '/registry-denied.json' => {
        www_root => $document_root,
      },
    },
    use_default_location      => false,
  }
}
