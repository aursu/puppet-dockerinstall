# Front the Docker daemon API with nginx doing mutual TLS and a client-certificate
# Common-Name allow-list.
#
# @summary nginx proxy in front of the Docker daemon, adding a client-cert CN allow-list
#
# The daemon's own `--tlsverify` checks only that a client certificate chains to
# the configured CA. Where that CA also signs every host and user certificate in
# an estate, chain-to-CA is not identity: any certificate the CA ever issued is
# accepted. This class puts nginx in front and adds the check the daemon has no
# way to express - a Common Name allow-list - so a validly signed certificate
# whose CN is not listed receives 403.
#
# It is meant to be paired with binding the daemon to loopback (see
# `dockerinstall::profile::daemon::tls_listen_ip`), so that the only route to the
# API from the network is through this proxy.
#
# @note
#   This vhost **requires** the `$connection_upgrade` map and deliberately does
#   **not** declare it. `aursu/nginx` already renders it in `00-proxy.conf`
#   whenever `nginx::proxy_connection_upgrade` is true, which is its default, and
#   `aursu/lsys_nginx` sets that explicitly. `aursu/gitlabinstall` renders the
#   same map in `98-gitlab-global-proxy` when its `manage_service` is false.
#
#   The map must exist exactly once. A second copy is
#   `duplicate variable "connection_upgrade"` and none at all is
#   `unknown "connection_upgrade" variable` - both are nginx startup failures,
#   not degraded vhosts, and this proxy usually shares its nginx with other
#   services. So this class depends on the map and fails at compile time if the
#   canonical provider is switched off, rather than shipping a third copy.
#
# @param allow_cn
#   Client-certificate Common Names permitted to reach the daemon. Everything
#   else gets 403. An empty list renders `map ... { default 0; }`, which is valid
#   nginx and denies everyone - safe, since it fails closed, and a legitimate way
#   to say "deny everyone for now". It warns rather than fails, because the usual
#   cause is an unseeded Hiera lookup and the symptom is loud.
#
# @param listen_ip
#   Address nginx listens on. Deliberately mandatory: a wildcard bind here would
#   reintroduce exactly the exposure this class exists to remove.
#
# @param upstream_host
#   Address the daemon listens on. Loopback by default, matching the intended
#   pairing with `tls_listen_ip`.
#
# @param ssl_cert
#   Certificate nginx presents to clients. It must be valid for the name clients
#   use in `DOCKER_HOST`, because a docker client with `DOCKER_TLS_VERIFY=1`
#   verifies it against `--tlscacert`.
#
# @param ssl_key
#   Key for `ssl_cert`. The nginx worker must be able to read it - see
#   `dockerinstall::tls::key_group`.
#
# @param ssl_client_ca
#   CA that client certificates are verified against.
#
# @param ssl_ca
#   CA used to verify the *upstream* daemon's certificate.
#
# @param proxy_ssl_name
#   Name the upstream certificate is verified against. Needed whenever
#   `upstream_host` is an IP address: certificates issued by a Puppet CA carry
#   the FQDN in the Common Name and have no IP SANs, so verifying the upstream
#   as `127.0.0.1` fails the name check and every request returns 502.
#
# @param port
#   Port nginx listens on, and by default the port the daemon listens on too.
#
# @param upstream_port
#   Port the daemon listens on, if it differs from `port`.
#
# @param server_name
#   Server name for the vhost. Defaults to the node's FQDN.
#
# @param proxy_timeout
#   Read and send timeout. The default of 60s would cut off `docker logs -f`,
#   `events`, and any long-running `exec`, so this is raised deliberately.
#
# @param manage_nginx_core
#   Whether this class brings up nginx itself, via `lsys_nginx`.
#
#   Default false, unlike `dockerinstall::registry::nginx` where nginx is the
#   deliverable. This class only adds one vhost in front of a daemon that is
#   already running, so taking ownership of the host's web server as a side
#   effect would be the wrong default: on any host that already has nginx from a
#   registry or GitLab profile that is a duplicate declaration, and the failure
#   arrives as a catalogue error naming a class the operator never mentioned.
#
#   Set it true only on a host that runs Docker and no web server at all. Left
#   false with nothing else declaring nginx, `nginx::resource::map` fails with
#   "You must include the nginx base class before using any defined resources",
#   which says plainly what is missing.
#
# @param manage_web_user
#   Whether to manage the web server user and group. Only used when
#   `manage_nginx_core` is true.
#
# @param manage_document_root
#   Whether to manage the document root directory. Only used when
#   `manage_nginx_core` is true.
#
# @param global_ssl_redirect
#   Whether nginx redirects plain HTTP to HTTPS globally. Only used when
#   `manage_nginx_core` is true.
#
# @example Daemon on loopback, one permitted client
#   class { 'dockerinstall::daemon_proxy':
#     listen_ip      => '10.0.0.10',
#     allow_cn       => ['builder.example.com'],
#     ssl_cert       => '/etc/docker/tls/cert.pem',
#     ssl_key        => '/etc/docker/tls/key.pem',
#     ssl_client_ca  => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
#     ssl_ca         => '/etc/docker/tls/ca.pem',
#     proxy_ssl_name => 'dockerhost.example.com',
#   }
class dockerinstall::daemon_proxy (
  Stdlib::IP::Address $listen_ip,
  Array[String[1]] $allow_cn,
  Stdlib::Absolutepath $ssl_cert,
  Stdlib::Absolutepath $ssl_key,
  Stdlib::Absolutepath $ssl_client_ca,
  Stdlib::Absolutepath $ssl_ca,
  String[1] $proxy_ssl_name,
  Stdlib::Port $port = 2376,
  Stdlib::IP::Address $upstream_host = '127.0.0.1',
  Optional[Stdlib::Port] $upstream_port = undef,
  Optional[Stdlib::Fqdn] $server_name = undef,
  Nginx::Time $proxy_timeout = '3600s',
  Boolean $manage_nginx_core = false,
  Boolean $manage_web_user = true,
  Boolean $manage_document_root = true,
  Boolean $global_ssl_redirect = true,
) {
  # A host may run Docker and no web server at all, in which case this class has
  # to bring nginx up itself. That is the exception, not the rule, so it is
  # opt-in: this class adds one vhost in front of an already-running daemon, and
  # the host's web server usually belongs to a registry or GitLab profile that
  # declares it resource-like.
  #
  # Deliberately NOT `include nginx` here. nginx::resource::* require the base
  # class but do not declare it, and an include-like declaration would collide
  # with a later resource-like `class { 'nginx': }` from the profile that really
  # owns it.
  # No proxy_connection_upgrade is passed here because lsys_nginx does not expose
  # one: it hardcodes `proxy_connection_upgrade => true` in its own nginx
  # declaration. So in this branch the $connection_upgrade map is guaranteed, and
  # the check below can never fire. The check exists for the other branch, where
  # the setting belongs to whichever profile owns nginx.
  if $manage_nginx_core {
    class { 'lsys_nginx':
      manage_user          => $manage_web_user,
      manage_document_root => $manage_document_root,
      global_ssl_redirect  => $global_ssl_redirect,
    }
  }

  # Deliberately a warning and not a failure: an empty list renders
  # `map ... { default 0; }`, which is valid nginx and refuses every client. That
  # fails CLOSED, so it is safe, and it is a legitimate way to say "deny everyone
  # for now". Compare the two fail() calls in this module - a contradictory key
  # mode, and a missing $connection_upgrade map - which are unsafe or leave nginx
  # unable to start. Blocking a whole node's catalogue over a safe, coherent
  # configuration would be the wrong trade.
  if empty($allow_cn) {
    warning(join([
          'dockerinstall::daemon_proxy: allow_cn is empty, so every client will be',
          'refused with 403. That is a valid deny-all and fails closed, but it is',
          'more often an unseeded Hiera lookup than an intention - check that first',
          'if Docker access has stopped working.',
    ], ' '))
  }

  # pick() rather than if/else: both fallbacks are always defined - the fqdn fact
  # and the $port default - so pick() cannot hit its all-undef error case.
  $vhost_name  = pick($server_name, $facts['networking']['fqdn'])
  $daemon_port = pick($upstream_port, $port)

  # Depend on the map, do not re-implement it - see the @note above. Where this
  # can be checked, checking it turns an nginx startup failure - which would take
  # every other vhost on the host down with it - into a catalogue error naming
  # the fix.
  #
  # Best effort, and deliberately guarded. The value is only readable once the
  # nginx class has been evaluated, and with manage_nginx_core false that is
  # another profile's business and may happen after this class. An unguarded read
  # would see undef and fail spuriously. The @note above is the real contract.
  if defined(Class['nginx']) and !$nginx::proxy_connection_upgrade {
    fail(join([
          'dockerinstall::daemon_proxy requires the $connection_upgrade map, which',
          'nginx::proxy_connection_upgrade is currently disabling. Docker hijacks the',
          'connection for exec and attach, so without it every job fails while',
          'simple calls keep working. Set nginx::proxy_connection_upgrade => true.',
    ], ' '))
  }

  # nginx has no native Common Name variable - unlike Apache's
  # $ssl_client_s_dn_cn it exposes only the full subject DN. The CN therefore
  # has to be extracted before it can be compared. RFC 2253 formatting (comma
  # separators) applies from nginx 1.11.6 onwards.
  #
  # The (^|,) anchor is load-bearing, not tidiness. Unanchored, `CN=` matches
  # anywhere in the DN - including inside another attribute's VALUE - and nginx
  # captures the first match. A certificate with, say,
  # `OU=xCN=allowed.example.com,CN=attacker` would then yield the allowed name
  # and pass the allow-list below. The allow-list is only as good as this regex.
  nginx::resource::map { 'ssl_client_s_dn_cn':
    string   => '$ssl_client_s_dn',
    default  => '""',
    mappings => [
      {
        # Ensures 'CN=' is either at the start of the string or follows a comma
        'key'   => '~(^|,)CN=(?<CN>[^,]+)',
        'value' => '$CN',
      },
    ],
  }

  # The allow-list itself. Anything not matched falls through to 0 and is
  # refused by the location below.
  $cn_mappings = $allow_cn.map |$cn| {
    { 'key' => "\"${cn}\"", 'value' => '1' }
  }

  nginx::resource::map { 'docker_ok':
    string   => '$ssl_client_s_dn_cn',
    default  => '0',
    mappings => $cn_mappings,
  }

  # `use_default_location` is REQUIRED and is not this module's default.
  # Without it nginx::resource::server renders a bare TLS listener with no
  # location block at all - no proxy_pass, and no CN check either - and nginx
  # starts happily and answers 404. A missing access control is completely
  # silent. Always read the rendered configuration on the host.
  #
  # `listen_port` equal to `ssl_port` is what makes the vhost SSL-only:
  # nginx::resource::server computes `ssl_only` from that equality rather than
  # taking a flag, so anything else leaves a plain-HTTP listener on the port.
  nginx::resource::server { "${vhost_name}-dockerd":
    server_name          => [$vhost_name],
    listen_ip            => $listen_ip,
    listen_port          => $port,
    ssl                  => true,
    ssl_port             => $port,
    ssl_cert             => $ssl_cert,
    ssl_key              => $ssl_key,
    ssl_client_cert      => $ssl_client_ca,
    ssl_verify_client    => 'on',
    ssl_verify_depth     => 2,
    ipv6_enable          => false,
    proxy                => "https://${upstream_host}:${daemon_port}",
    proxy_read_timeout   => $proxy_timeout,
    proxy_send_timeout   => $proxy_timeout,
    proxy_http_version   => '1.1',
    use_default_location => true,
    location_raw_prepend => [
      'if ($docker_ok = 0) { return 403; }',
    ],
    # The whole proxy_ssl_* group is injected raw and kept together. Most of
    # these have no parameter on nginx::resource::server, and the one that does
    # - proxy_ssl_trusted_certificate - only gained it in a later release than
    # some consumers pin, so relying on it would tie this class to an
    # aursu/nginx version for no benefit. The daemon runs with --tlsverify,
    # which means nginx must authenticate to it as a client, not merely trust it.
    location_raw_append  => [
      "proxy_ssl_certificate ${ssl_cert};",
      "proxy_ssl_certificate_key ${ssl_key};",
      "proxy_ssl_trusted_certificate ${ssl_ca};",
      'proxy_ssl_verify on;',
      'proxy_ssl_verify_depth 2;',
      "proxy_ssl_name ${proxy_ssl_name};",
      'proxy_ssl_server_name on;',
      # Docker hijacks the connection for exec, attach and `run -it`. Without
      # these the simple calls keep working while those fail, so a smoke test
      # that only runs `docker version` passes over a broken proxy.
      'proxy_set_header Upgrade $http_upgrade;',
      'proxy_set_header Connection $connection_upgrade;',
      # Streaming endpoints (logs -f, events, attach) and large request bodies
      # (build context, image push) must not be buffered.
      'proxy_buffering off;',
      'proxy_request_buffering off;',
    ],
  }
}
