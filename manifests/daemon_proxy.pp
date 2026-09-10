# Front the Docker daemon API with nginx doing mutual TLS and a client-certificate
# Common-Name allow-list.
#
# @summary stream proxy in front of the Docker daemon, adding a client-cert CN allow-list
#
# The daemon's own `--tlsverify` checks only that a client certificate chains to
# the configured CA. Where that CA also signs every host and user certificate in
# an estate, chain-to-CA is not identity: any certificate the CA ever issued is
# accepted. This class puts nginx in front and adds the check the daemon has no
# way to express - a Common Name allow-list - so a validly signed certificate
# whose CN is not listed is refused.
#
# It is meant to be paired with binding the daemon to loopback (see
# `dockerinstall::profile::daemon::tls_listen_ip`), so that the only route to the
# API from the network is through this proxy.
#
# @note
#   **This is a `stream` (layer 4) proxy, and it has to be.** An earlier version
#   used the http proxy module and failed in a way worth recording, because every
#   obvious symptom looked healthy: `version`, `ps` and `logs` worked, containers
#   ran, exit codes propagated, and nginx logged `101` for each hijack. But
#   `run`, `exec` and any piped stdin produced no output at all.
#
#   The cause is TCP half-close. A Docker client with nothing more to send shuts
#   down its write side while still reading output, and the daemon understands
#   that. `ngx_http_proxy_module` treats an upgraded connection as a WebSocket
#   and tears the whole tunnel down on the client's FIN, so the return path dies
#   before any output crosses it - hence `101` with zero bytes.
#
#   Measured rather than inferred: holding stdin open made the identical command
#   work through the same proxy. `proxy_half_close`, which fixes it, exists only
#   in `ngx_stream_proxy_module`. Do not move this back to an http server block.
#
# @note
#   **The allow-list decides which upstream `proxy_pass` targets, and that is not
#   a stylistic choice.** The stream module has no conditional at content phase -
#   no `if`, and `return` cannot be selected per connection alongside
#   `proxy_pass` - so the only lever that varies per connection is the upstream
#   address. Allow-listed Common Names map to the daemon; everything else maps to
#   a listener that answers and immediately closes.
#
#   An njs `js_access` handler was tried first and does not work: **that phase
#   runs before the TLS handshake completes**, so `$ssl_client_s_dn` is still
#   empty when it reads it and every client is refused. `proxy_pass` with a
#   variable is resolved at the content phase, after the handshake, which is why
#   this form sees the certificate and the njs one could not. Measured on a live
#   host, both directions. Do not reach for njs here again.
#
# @param allow_cn
#   Client-certificate Common Names permitted to reach the daemon. Everything
#   else is refused. An empty list refuses everyone, which is safe - it fails
#   closed - and a legitimate way to say "deny everyone for now", so it warns
#   rather than fails.
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
#   as `127.0.0.1` fails the name check and every connection fails.
#
# @param port
#   Port nginx listens on, and by default the port the daemon listens on too.
#
# @param upstream_port
#   Port the daemon listens on, if it differs from `port`.
#
# @param server_name
#   Name used for the generated configuration files. Defaults to the node's FQDN.
#
# @param proxy_timeout
#   Stream proxy timeout. The default would cut off a long `docker logs -f`,
#   `events`, or a slow build, so this is raised deliberately.
#
# @param deny_listen_ip
#   Address of the refusal listener. Loopback: it exists only to close
#   connections that failed the Common Name check, and must never be reachable.
#
# @param deny_port
#   Port for the refusal listener. A high port by default rather than something
#   like `1`, so it needs no privilege and reads as deliberate.
#
# @param manage_nginx_core
#   Whether this class brings up nginx itself, via `lsys_nginx`, with `stream`
#   enabled.
#
#   Default false, unlike `dockerinstall::registry::nginx` where nginx is the
#   deliverable. This class only adds a listener in front of a daemon that is
#   already running, so taking ownership of the host's web server as a side
#   effect would be the wrong default: on any host that already has nginx from a
#   registry or GitLab profile that is a duplicate declaration.
#
#   Left false, **the profile that owns nginx must set `lsys_nginx::stream` to
#   true**. Without it there is no `conf.stream.d` and none of this renders.
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
  Stdlib::IP::Address $deny_listen_ip = '127.0.0.1',
  Stdlib::Port $deny_port = 12376,
  Optional[Stdlib::Absolutepath] $stream_conf_dir = undef,
  Boolean $manage_nginx_core = false,
  Boolean $manage_web_user = true,
  Boolean $manage_document_root = true,
  Boolean $global_ssl_redirect = true,
) {
  # nginx::params is a bare, parameterless params class: including it is safe
  # from anywhere and imposes no ordering requirement, which is precisely why the
  # stream configuration directory is derived from it rather than from
  # $nginx::conf_dir. See the stream_conf_dir documentation.
  include nginx::params

  # A host may run Docker and no web server at all, in which case this class has
  # to bring nginx up itself, with stream enabled. That is the exception, not the
  # rule, so it is opt-in: the host's web server usually belongs to a registry or
  # GitLab profile that declares it.
  #
  # Deliberately NOT `include nginx` here. nginx::resource::* require the base
  # class but do not declare it, and an include-like declaration would collide
  # with a later resource-like `class { 'nginx': }` from the profile that really
  # owns it.
  if $manage_nginx_core {
    class { 'lsys_nginx':
      manage_user          => $manage_web_user,
      manage_document_root => $manage_document_root,
      global_ssl_redirect  => $global_ssl_redirect,
      stream               => true,
    }
  }

  # Deliberately a warning and not a failure: an empty list renders
  # `map ... { default 0; }`, which refuses every client. That fails CLOSED, so
  # it is safe, and it is a legitimate way to say "deny everyone for now".
  # Blocking a whole node's catalogue over a safe, coherent configuration would
  # be the wrong trade.
  if empty($allow_cn) {
    warning(join([
          'dockerinstall::daemon_proxy: allow_cn is empty, so every client will be',
          'refused. That is a valid deny-all and fails closed, but it is more often',
          'an unseeded Hiera lookup than an intention - check that first if Docker',
          'access has stopped working.',
    ], ' '))
  }

  # pick() rather than if/else: both fallbacks are always defined - the fqdn fact
  # and the $port default - so pick() cannot hit its all-undef error case.
  $vhost_name  = pick($server_name, $facts['networking']['fqdn'])
  $daemon_port = pick($upstream_port, $port)

  # Derived from nginx::params rather than from $nginx::conf_dir, and that is the
  # whole point: nginx::params is a bare parameterless params class, so including
  # it is always safe and carries no ordering requirement, while $nginx::conf_dir
  # only exists once the nginx class itself has been evaluated - which, with
  # manage_nginx_core false, is another profile's business and frequently
  # happens after this one. Reading it there fails the catalogue outright with
  # "Unknown variable: 'nginx::conf_dir'".
  #
  # It is still the source of truth rather than a literal: both nginx::conf_dir
  # and lsys_nginx's own conf_dir default to nginx::params::conf_dir, and it is
  # platform-aware - /etc/nginx on Linux, /usr/local/etc/nginx on FreeBSD.
  #
  # The one case it gets wrong is a site that overrides conf_dir away from that
  # default. stream_conf_dir is the override for exactly that, which is why it
  # stays.
  #
  # if/else rather than pick(): Puppet evaluates function arguments eagerly, so
  # pick($stream_conf_dir, "${nginx::params::conf_dir}/...") would read the params
  # class even when the parameter is set. Harmless here, but the same shape bites
  # whenever the fallback is not free.
  if $stream_conf_dir {
    $stream_dir = $stream_conf_dir
  }
  elsif defined(Class['nginx']) {
    # The real configured value, when the nginx class has already been evaluated.
    $stream_dir = "${nginx::conf_dir}/conf.stream.d"
  }
  else {
    # Otherwise the platform default both nginx and lsys_nginx derive from. Right
    # for every site that does not move conf_dir, and the parameter above covers
    # the ones that do.
    $stream_dir = "${nginx::params::conf_dir}/conf.stream.d"
  }

  # Best effort, and deliberately guarded: the value is only readable once the
  # nginx class has been evaluated, and with manage_nginx_core false that is
  # another profile's business and may happen after this class. An unguarded read
  # would see undef and fail spuriously.
  if defined(Class['nginx']) and !$nginx::stream {
    fail(join([
          'dockerinstall::daemon_proxy requires the nginx stream module, which is',
          'not enabled. Set lsys_nginx::stream (or nginx::stream) to true on this',
          'host - without it there is no conf.stream.d and this proxy renders',
          'nothing at all.',
    ], ' '))
  }

  # nginx has no native Common Name variable - unlike Apache's
  # $ssl_client_s_dn_cn it exposes only the full subject DN. The CN therefore
  # has to be extracted before it can be compared.
  #
  # The (^|,) anchor is load-bearing, not tidiness. Unanchored, `CN=` matches
  # anywhere in the DN - including inside another attribute's VALUE - and nginx
  # captures the first match. A certificate with, say,
  # `OU=xCN=allowed.example.com,CN=attacker` would then yield the allowed name
  # and pass the allow-list below. The allow-list is only as good as this regex.
  nginx::resource::map { 'ssl_client_s_dn_cn':
    context  => 'stream',
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

  # The allow-list itself, expressed as the upstream each Common Name reaches.
  # Anything not matched falls through to the refusal listener.
  $cn_mappings = $allow_cn.map |$cn| {
    { 'key' => "\"${cn}\"", 'value' => "${upstream_host}:${daemon_port}" }
  }

  nginx::resource::map { 'docker_backend':
    context  => 'stream',
    string   => '$ssl_client_s_dn_cn',
    default  => "${deny_listen_ip}:${deny_port}",
    mappings => $cn_mappings,
  }

  # Declared absent for one release: 0.36.2 and earlier shipped an njs shim here,
  # and removing a resource from a manifest orphans the file rather than deleting
  # it. Drop these two once every consumer has converged.
  file { '/usr/lib/nginx/njs/dockerd_access.js':
    ensure => absent,
  }

  file { "${stream_dir}/00-dockerd-njs.conf":
    ensure => absent,
  }

  file { "${stream_dir}/00-dockerd-deny.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('dockerinstall/stream/dockerd_deny.conf.erb'),
  }

  # `listen_options => 'ssl'` is what terminates TLS here; the certificate
  # directives have no parameters on streamhost and are injected raw.
  #
  # proxy_half_close is the whole reason this is a stream server - see the note
  # on the class. Without it a client that half-closes has its return path torn
  # down, which looks like success and delivers nothing.
  nginx::resource::streamhost { "${vhost_name}-dockerd":
    listen_ip          => $listen_ip,
    listen_port        => $port,
    listen_options     => 'ssl',
    ipv6_enable        => false,
    proxy              => '$docker_backend',
    proxy_read_timeout => $proxy_timeout,
    raw_prepend        => [
      "ssl_certificate ${ssl_cert};",
      "ssl_certificate_key ${ssl_key};",
      "ssl_client_certificate ${ssl_client_ca};",
      'ssl_verify_client on;',
      'ssl_verify_depth 2;',
    ],
    raw_append         => [
      'proxy_half_close on;',
      'proxy_ssl on;',
      "proxy_ssl_certificate ${ssl_cert};",
      "proxy_ssl_certificate_key ${ssl_key};",
      "proxy_ssl_trusted_certificate ${ssl_ca};",
      'proxy_ssl_verify on;',
      'proxy_ssl_verify_depth 2;',
      "proxy_ssl_name ${proxy_ssl_name};",
      'proxy_ssl_server_name on;',
    ],
  }

  # The refusal listener must exist before anything can be pointed at it.
  File["${stream_dir}/00-dockerd-deny.conf"]
  -> Nginx::Resource::Streamhost["${vhost_name}-dockerd"]
}
