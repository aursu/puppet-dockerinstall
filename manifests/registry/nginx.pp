# @summary Registry Nginx setup
#
# Registry Nginx setup
#
# @example
#   include dockerinstall::registry::nginx
class dockerinstall::registry::nginx (
  String $server_name,
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

  $nginx_upstream_members = $dockerinstall::registry::params::nginx_upstream_members
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
    ssl_protocols             => 'TLSv1.2',
    ssl_ciphers               => 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256', # lint:ignore:140chars
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
