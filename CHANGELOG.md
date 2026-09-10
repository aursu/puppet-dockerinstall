# Changelog

All notable changes to this project will be documented in this file.

## Release 0.36.2

* **The stream configuration directory now prefers `$nginx::conf_dir` and falls back to `nginx::params::conf_dir`.** 0.36.1 used the params class unconditionally, which is safe but only ever the platform *default* - a site that moved `conf_dir` would still have been wrong. The class now takes the real configured value whenever the nginx class has already been evaluated, and the params default otherwise, so ordering the declaration correctly is rewarded without being required.
* `include nginx::params` moves to the top of the class, where a class-wide dependency belongs, rather than sitting next to the one expression that uses it.

## Release 0.36.1

**Bugfixes**

* **The stream configuration directory is derived from `nginx::params::conf_dir`, not `$nginx::conf_dir`.** 0.36.0 restored the read of the nginx class on the theory that the declaring profile could simply be ordered to evaluate nginx first. Measured against a real node, that did not hold - the catalogue still failed with `Unknown variable: 'nginx::conf_dir'` after the reorder.
* `nginx::params` is a bare, parameterless params class, so including it is safe from anywhere and imposes no ordering requirement at all. It remains the source of truth rather than a literal: both `nginx::conf_dir` and `lsys_nginx`'s own conf_dir default to it, and it is platform-aware. `stream_conf_dir` still overrides, for sites that move conf_dir away from that default - which is the one case the derivation cannot see.

## Release 0.36.0

**Bugfixes**

* **`stream_conf_dir` now derives from `${nginx::conf_dir}/conf.stream.d` again**, instead of defaulting to a hardcoded `/etc/nginx/conf.stream.d`. 0.35.1 fixed the compile failure by writing the same value down a second time, where nothing kept it true: a site that moved `nginx::conf_dir` would have had this configuration written to a directory nginx does not read, and the only symptom would have been `js_import` never loading.
* The parameter remains, as `Optional` and `undef` by default, for layouts where the nginx class genuinely cannot be evaluated first. **The ordering is the real fix** - the profile declaring this class must declare the profile that owns nginx ahead of it - and getting it wrong still fails loudly at compile time rather than quietly.
* The derivation uses `if`/`else` rather than `pick()` deliberately: Puppet evaluates function arguments eagerly, so `pick($stream_conf_dir, "${nginx::conf_dir}/...")` would read the nginx class even when the parameter is set, failing for exactly the layouts the parameter exists to rescue.

## Release 0.35.1

**Bugfixes**

* **`dockerinstall::daemon_proxy` no longer reads `$nginx::conf_dir`**, which broke catalogue compilation outright: `Unknown variable: 'nginx::conf_dir'`. With `manage_nginx_core` false this class does not declare the nginx class, and the profile that does is frequently evaluated *after* it - at which point the variable does not exist yet. The path now comes from a `stream_conf_dir` parameter defaulting to `/etc/nginx/conf.stream.d`.
* This is the same ordering hazard the `stream` check already guards against with `defined(Class['nginx'])`. Unit tests did not catch it because rspec-puppet's `pre_condition` always runs first, so nginx is never "declared later" in a spec - the failure only appears against a real node. A `stream_conf_dir` test now guards against reintroducing the read, since sourcing the path from the nginx class again would ignore the parameter.

## Release 0.35.0

**Bugfixes**

* **`dockerinstall::daemon_proxy` is now a `stream` (layer 4) server, not an http one.** The http version was broken in a way that looked healthy: `docker version`, `ps` and `logs` worked, containers ran, exit codes propagated, and nginx logged `101` for every hijack - but `run`, `exec` and any piped stdin produced no output at all.

  The cause is TCP half-close. A Docker client with nothing more to send shuts down its write side while still reading output, and the daemon understands that; `ngx_http_proxy_module` treats an upgraded connection as a WebSocket and tears the whole tunnel down on the client's FIN, so the return path dies before any output crosses it. Measured rather than inferred: holding stdin open made the identical command work through the same proxy. `proxy_half_close`, which fixes it, exists only in `ngx_stream_proxy_module`.

**Features**

* The Common Name check moves from an `if ... return 403` in an http location to an njs `js_access` handler, because the stream module cannot refuse a connection based on a variable - its access module filters by address only, and there is no `return` in stream context. **The allow-list stays in Puppet-rendered nginx maps**; the JavaScript is a fixed shim that reads `$docker_ok` and never changes when the list does.
* New `js_dir` parameter, defaulting to `/usr/lib/nginx/njs` - the sibling of `/usr/lib/nginx/modules`, where the njs module itself installs. nginx defines no standard location for njs scripts.
* `manage_nginx_core` now enables `njs` and `stream` on `lsys_nginx`, and gains `njs_package_ensure`. Where another profile owns nginx, that profile must set both - without `stream` there is no `conf.stream.d`, and without `njs` nginx will not start because the generated configuration names a module that is not loaded.
* Requires `aursu/lsys_nginx >= 0.49.0` for those two parameters.

**Notes**

* The CN extraction regex keeps its `(^|,)` anchor, and there is a spec asserting it. Unanchored, `CN=` matches anywhere in the subject DN including inside another attribute's value, so a certificate carrying `OU=xCN=allowed.example.com,CN=attacker` would yield the allow-listed name and pass.
* Rejections happen in two places and it is worth knowing which: an unknown CA, an expired certificate or no certificate at all is refused by the TLS handshake, since the server sets `ssl_verify_client on` - the njs handler never runs. A valid certificate whose CN is not listed is refused by the handler, and logged there.

## Release 0.34.0

**Features**

* **`dockerinstall::profile::daemon` now composes `dockerinstall::daemon_proxy`** via `proxy_enable`, rather than leaving a site profile to declare it. Everything the proxy needs is already known here - the TLS asset directory, the CA path, the node's certname, and above all the daemon's own `tls_listen_ip`, which becomes the proxy's `upstream_host`. Those two are the pair that must never disagree, and composing them in one class means they cannot.
* New parameters: `proxy_enable`, `proxy_allow_cn`, `proxy_listen_ip` (defaults to the node's primary address), `proxy_port` (2376), `proxy_ssl_name` (defaults to the node's certname) and `proxy_manage_nginx_core`. All default to off or to derived values, so nothing changes for existing users.
* **`proxy_enable` without `tls_enable` fails at compile time.** The proxy authenticates to the daemon with a client certificate, so a daemon not listening with TLS gives it nothing to reach - better a catalogue error than a vhost proxying to a closed port.

## Release 0.33.0

**Features**

* **New class `dockerinstall::daemon_proxy`** - nginx in front of the Docker daemon API doing mutual TLS plus a client-certificate **Common Name allow-list**. The daemon's own `--tlsverify` only checks that a client certificate chains to the configured CA; where that CA also signs every host and user certificate in an estate, chain-to-CA is not identity. This adds the check the daemon has no way to express, so a validly signed certificate whose CN is not listed gets 403.
* **`dockerinstall::profile::daemon` gains `tls_listen_ip`** - the address the TLS API binds to. The bind was previously hardcoded to `tcp://0.0.0.0:2376`. `undef` keeps that wildcard, so no existing node moves; a loopback address takes the API off the network, which is the intended pairing with `daemon_proxy`.
* **`dockerinstall::tls` gains `key_group`**, plumbed through `dockerinstall::profile::daemon` as `tls_key_group` - mode `0640` with a named group, for the case where a proxy running as another user must authenticate to the daemon. It **fails at compile time** if combined with `users_access`: the two are opposite intentions about the same file, and a silent mode surprise on a private key is worth an error.
* `dockerinstall::daemon_proxy` takes `manage_nginx_core`, **defaulting to false** - unlike `dockerinstall::registry::nginx`, where nginx is the deliverable and true is right. This class only adds a vhost in front of an already-running daemon, so taking ownership of the host's web server as a side effect would be the wrong default. Set it true on a host that runs Docker and no web server at all.
* All parameters of `dockerinstall::profile::daemon` are documented now. It had none, so documenting only the new ones would have left lint warnings behind.

**Notes on four details that are load-bearing rather than stylistic**, all recorded in the code:

* **The `$connection_upgrade` map is depended on, not re-implemented.** `aursu/nginx` already renders it in `00-proxy.conf` whenever `nginx::proxy_connection_upgrade` is true (its default; `aursu/lsys_nginx` sets it explicitly), and `aursu/gitlabinstall` renders the same map in `98-gitlab-global-proxy` when its `manage_service` is false. The map must exist **exactly once**: a second copy is `duplicate variable "connection_upgrade"`, none at all is `unknown "connection_upgrade" variable`, and both are nginx **startup** failures that take every other vhost on the host with them.
* **The Common Name is extracted with `~(^|,)CN=(?<CN>[^,]+)`, and the anchor is a security control.** Unanchored, `CN=` matches anywhere in the subject DN - including inside another attribute's value - and nginx captures the first match, so a certificate carrying `OU=xCN=allowed.example.com,CN=attacker` would yield the allow-listed name and pass. There is a spec asserting the anchored form; do not relax it.
* **`proxy_ssl_name` is mandatory.** Certificates issued by a Puppet CA carry the FQDN in the Common Name and have no IP SANs, so verifying a loopback upstream as `127.0.0.1` fails the name check and every request returns 502.
* **Docker hijacks the connection** for `exec`, `attach` and `run -it`, so the vhost sets `proxy_http_version 1.1` with the `Upgrade`/`Connection` headers. Without them the simple calls keep working while those fail - a smoke test that only runs `docker version` passes over a broken proxy.

## Release 0.32.0

**Features**

* **`dockerinstall::profile::registry` gains `api_listen_ip`, `api_allow` and `api_port`** - an optional second vhost serving the registry API over TLS, restricted to an explicit list of source addresses, proxying to the registry on loopback. `undef` by default, so nothing is created for existing users.
* **Why it exists.** The main vhost is built for docker clients: it can require mutual TLS and it gates `/v2/*` behind the registry auth-token map. A client that speaks the registry API directly with its own bearer token - GitLab's registry integration is the usual one - satisfies neither, which is why such setups traditionally reach the container's published port over plain HTTP from wherever they happen to be. This replaces that with TLS and an allow-list. Measured against a live pair of hosts: `/v2/_catalog` answers 200 through this vhost and 403 through the main one.
* ⚠ Two details that are load-bearing rather than stylistic, both recorded in the code. `use_default_location` is set explicitly because this module defaults it to **false**: without it the vhost renders as a bare TLS listener with no location at all - no `proxy_pass`, and **no allow/deny either**, so the access restriction silently does not exist while nginx starts happily and answers 404. And `listen_port` equals `ssl_port` because `nginx::resource::server` computes `ssl_only` from that equality rather than taking a flag; anything else leaves a plain-HTTP listener on the port.
* All parameters of the class are documented now. It had none, so documenting only the new ones would have left ten lint warnings behind.

## Release 0.31.0

**Features**

* **`dockerinstall::registry::nginx::upstream_host`** - the address nginx proxies to for the registry, default `localhost`. The upstream members hash was a local variable read from `params`, so it could not be reached from Hiera at all; it is now built from this parameter.
* ⚠ **Set it whenever `dockerinstall::registry::base::listen_ip` names a specific non-loopback address.** The two belong together: binding the container to an internal address while nginx still proxies to `localhost` leaves nginx unable to reach it, and **every pull through the registry fails with 502 Bad Gateway** - measured on a live registry on 2026-09-09. Loopback needs no change here; a specific address does. The registry's nginx error log names the upstream it could not reach, which is the quickest way to recognise it.
* All ten parameters of `dockerinstall::registry::nginx` are now documented. The class previously had none, so adding one would have left nine lint warnings behind.

## Release 0.30.0

**Features**

* **`dockerinstall::registry::base::listen_ip`** - publish the registry port on one host address instead of every interface. Default `undef` keeps Docker's own behaviour, so nothing moves for existing consumers; setting it renders `<ip>:5000:5000` rather than `5000:5000`. The registry's external surface is then whatever fronts it on `:443`, not the container port.
* ⚠ **Anything reaching the registry on `localhost:5000` has to move to the same address.** Where GitLab manages the registry that means `registry_api_url`, which defaults to `http://localhost:5000` and is what GitLab uses to delete tags, report image sizes and run cleanup policies. It fails quietly rather than loudly when the address stops answering, so the two settings change together or not at all. The parameter documentation says so at the point of use.

## Release 0.29.0

**Features**

* **`dockerinstall::webservice`'s `decomission` now actually removes the service.** It previously removed the project secrets and set the compose service to `stopped`, which left the containers, the project network and the compose configuration file on disk — a service switched off rather than decommissioned, whose published ports return on the next `up`. The branch now takes the project down with `compose down --remove-orphans`, then removes the compose configuration file and the project directory. Ordered deliberately: `compose down` needs the file to identify what it is tearing down, so the file is removed only after the project is down, and the `exec` is guarded with `onlyif test -f <compose file>` so it is a no-op once gone.
* ⚠ **The decomission branch deliberately does not declare `dockerinstall::composeservice`.** The `dockerservice` type writes the compose configuration as a *property*, so declaring the service in this branch would rewrite the very file being removed and the two owners would fight on every run. This is also why the type's `stopped` value is no longer used here — `compose stop` cannot express removal, and the type has no `absent`.
* **`decomission_volumes`** (default `false`) — additionally pass `--volumes`, removing named volumes the project declares. Off by default because volume contents are not recoverable and a project's data is often the one thing worth keeping.
* **`decomission_image`** (default `false`, requires `manage_image`) — additionally remove the service image from the host. Off by default because an image is frequently shared with other projects on the same host.

## Release 0.28.4

**Bugfixes**

* Fixed Ruby `LoadError` for `puppet_x/dockerinstall` by adding proper `$LOAD_PATH` configuration
* Added `$LOAD_PATH.unshift` to `dockerservice` type and `compose` provider to ensure Ruby can locate shared utility module
* Resolved "no such file to load -- puppet_x/dockerinstall" error on Puppet server

**Known Issues**

## Release 0.28.3

**Features**

* Added `uid` and `gid` optional parameters to `Dockerinstall::Secret` type for setting file ownership
* Enhanced `dockerinstall::webservice` to apply `owner` and `group` attributes when creating secret files

**Known Issues**

## Release 0.28.2

**Improvements**

* Enhanced Docker Compose version detection for compatibility with both v2.x and v5.x formats
* Fixed `composeplugin` provider to use `docker compose version` command (instead of `--version` flag)
* Updated `compose` provider version regex to support all Docker Compose versions (not just v1/v2)
* Refactored `composev2` provider version detection with fallback support
* Added unit tests for `composeplugin` provider version parsing

**Known Issues**

## Release 0.28.1

**Improvements**

* Updated default Docker Compose version to 5.0.2
* Updated test suite regex patterns to match Docker Compose v5.x version format

**Known Issues**

## Release 0.28.0

**Features**

* Enhanced `project_volumes` parameter to support flexible Docker Compose volume configurations
* Added support for volume configuration with `driver` and `driver_opts` for advanced storage backends (e.g., NFS)
* Added support for volume labels in both hash and array formats
* Added support for volume `name` and `external` properties for external volume management
* Added support for mixed volume configurations (combining string declarations and hash configurations)

**Improvements**

* Enhanced service.yaml.erb template to handle nested hash configurations for driver_opts
* Enhanced template to properly quote values in nested configurations for YAML compliance
* Enhanced template to support array values for labels and other volume properties
* Added comprehensive test suite with 130 examples covering all volume configuration patterns

**Known Issues**

## Release 0.27.0

**Bugfixes**

* Fixed duplicate File resource declaration in `dockerinstall::webservice` when both `project_secrets` and `env_name`/`secrets` parameters are specified
* Added test coverage for edge case with simultaneous `project_secrets`, `env_name`, and `secrets` parameters
* Refactored secrets directory management to use conditional creation based on `$need_secrets_dir` variable

**Improvements**

* Improved resource management logic by consolidating duplicate File resource declarations
* Enhanced test suite with additional edge case coverage

**Known Issues**

## Release 0.26.0

**Features**

* Added comprehensive unit tests for `PuppetX::Dockerinstall` module covering all validation methods
* Enhanced YAML parsing and validation
* Improved code organization by moving validation logic to shared `PuppetX::Dockerinstall` module
* Added helper methods

**Bugfixes**

* Fixed Rubocop conventions
* Fixed puppet-lint warnings
* Removed dead code: unused `configuration_validate` and `configuration_integrity` methods from compose provider
* Removed unused `validate_build_requirements` method from PuppetX module
* Fixed line length violations in puppet manifests

**Improvements**

* Standardized code style across all Ruby files
* Added `.puppet-lint.rc` configuration for parameter documentation checks
* Enhanced documentation comments in `PuppetX::Dockerinstall` module

**Known Issues**

## Release 0.25.0

**Features**

* Refactored basedir determination logic to use shared helper module `PuppetX::Dockerinstall`
* Fixed dockerservice type to properly handle basedir defaultto without provider initialization timing issues
* Fixed path munging to use consistent basedir logic across type and providers
* Added build parameter validation in type validate block for better error messages

**Bugfixes**

* Fixed basedir parameter to return default value when not explicitly set
* Fixed configuration validation to properly check service existence
* Fixed build validation to execute during resource creation

**Known Issues**

## Release 0.24.0

**Features**

* Added `docker_secret` parameter to dockerinstall::webservice for Docker Compose secrets configuration
* Added `project_secrets` parameter to dockerinstall::webservice for project-level secrets definition
* Fixed variable naming conflict: renamed internal `$project_secrets` to `$project_secrets_path`

**Bugfixes**

**Known Issues**

## Release 0.23.5

**Features**

* Added `traces_disabled` parameter to Docker registry base class for OpenTelemetry traces control
* Added `OTEL_TRACES_EXPORTER` environment variable support to disable OpenTelemetry traces

**Bugfixes**

**Known Issues**

## Release 0.1.0

**Features**

**Bugfixes**

**Known Issues**

## Release 0.6.1

**Features**

**Bugfixes**

* Added token certificate directory into Puppet management

**Known Issues**

## Release 0.6.2

**Features**

**Bugfixes**

* Hardcoded certificate path
* Bind certificate directory into registry container

**Known Issues**

## Release 0.6.3

**Features**

**Bugfixes**

* Bind certificate into registry container instead certificate directory

**Known Issues**

## Release 0.6.4

**Features**

**Bugfixes**

* Added ability to not import token certificate from PuppetDB (eg when registry
  and GitLab reside on the same server)

**Known Issues**

## Release 0.7.0

**Features**

* Added ability to build docker image before service run (for dockerservice)

**Bugfixes**

**Known Issues**

## Release 0.7.1

**Features**

* Added docker compose parameters privileged and command
* Added template for tokens' map

**Bugfixes**

**Known Issues**

## Release 0.8.0

**Features**

* Added authorization settings into Nginx

**Bugfixes**

**Known Issues**

## Release 0.8.1

**Features**

* Added ability to pass build image flag from webservice

**Bugfixes**

**Known Issues**

## Release 0.8.2

**Features**

**Bugfixes**

* Removed coontext and docker file existing check
* bugfix: Docker Compose does not support tarball contexts

**Known Issues**

## Release 0.8.3

**Features**

**Bugfixes**

* Bugfix: directory /etc/docker/registry should be defined in case of registry
  token authentication

**Known Issues**

## Release 0.9.0

**Features**

* Added Docker decomission profile

**Bugfixes**

**Known Issues**

## Release 0.9.1

**Features**

* Added Docker 20.10 support
* Added CentOS 8 support

**Bugfixes**

**Known Issues**

## Release 0.9.2

**Features**

**Bugfixes**

* Added Docker daemon restart during Docker upgrade

**Known Issues**

## Release 0.9.3

**Features**

**Bugfixes**

* Updated dependencies

**Known Issues**

## Release 0.9.4

**Features**

**Bugfixes**

* Adjusted module settings and dependencies

**Known Issues**

## Release 0.9.5

**Features**

**Bugfixes**

* Added missed dependency class into dockerinstall::registry::clientauth

**Known Issues**

## Release 0.10.0

**Features**

* Added containment for several calsses and resources

**Bugfixes**

**Known Issues**

## Release 0.10.1

**Features**

**Bugfixes**

* Added additional dependencies during decomission

**Known Issues**

## Release 0.10.2

**Features**

* Default docker compose version set to 1.29.2

**Bugfixes**

**Known Issues**

## Release 0.10.3

**Features**

* PDK upgrade to version 2.3.0

**Bugfixes**

**Known Issues**

## Release 0.11.0

**Features**

* Added option selinux-enabled in daemon.json
* Default Docker Compose version set to 2.2.2

**Bugfixes**

**Known Issues**

## Release 0.12.0

**Features**

* Added ability to install Docker Compose CLI plugin fro Compose v2+

**Bugfixes**

* Fixed Docker Compose v2+ installation
* Fixed Dockerservice provider to support Docker Compose v2+

**Known Issues**

## Release 0.12.1

**Features**

**Bugfixes**

* Fixed dockerservice provider for never version docker compose
  container name and project separator now is "-" instead "_"

**Known Issues**

## Release 0.13.0

**Features**

* Updated fixtures and module meta

**Bugfixes**

* Removed dependency on systemd::systemctl::daemon_reload

**Known Issues**

## Release 0.13.1

**Features**

* Added repository metadata update commands

**Bugfixes**

**Known Issues**

## Release 0.13.2

**Features**

* Updated composer

**Bugfixes**

* Fixed athentication issue

**Known Issues**

## Release 0.13.3

**Features**

**Bugfixes**

* Updated version to cover Ubuntu versions

**Known Issues**

## Release 0.13.5

**Features**

* Added flag to allow users access to Docker TLS assets
* Added this flag  into `install` and  `daemon` pofiles

**Bugfixes**

**Known Issues**

## Release 0.13.6

**Features**

* Docker registry default version 2.8.1

**Bugfixes**

**Known Issues**

## Release 0.14.1

**Features**

* PDK version 3.0.0

**Bugfixes**

* Fixed PDK warnings

**Known Issues**

## Release 0.15.0

**Features**

**Bugfixes**

* Fixed error with container status for docker compose 2.14.1+

**Known Issues**

## Release 0.16.1

**Features**

* Setup `aursu/nginx` as a dependency

**Bugfixes**

* Added support for Ubuntu Focal package version

**Known Issues**

## Release 0.17.0

**Features**

* Setup `aursu/lsys_nginx` as a dependency

**Bugfixes**

**Known Issues**

## Release 0.17.1

**Features**

* Added docker version 25.x

**Bugfixes**

**Known Issues**

## Release 0.18.0

**Features**

* Added docker version 26.x

**Bugfixes**

**Known Issues**

## Release 0.19.2

**Features**

* Added Windows support for private Registries auth

**Bugfixes**

* Fixed paths to Windows keys

**Known Issues**

## Release 0.22.0

**Features**

* Added Windows support for private Registries auth (inside user home directory)
* PDK upgrade to 3.3.0
* Updated Ubuntu repo
* Added docker compose plugin provider for custom type `dockerservice`

**Bugfixes**

**Known Issues**

## Release 0.23.3

**Features**

* Updated module dependencies
* Added ability to disable access logs in registry

**Bugfixes**

* Added 27.x/28.x into list of allowed versions
* Added compatibility with new puppet module
* Removed deprecated `version` top scope Compose parameter

**Known Issues**

## Release 0.23.4

**Features**

**Bugfixes**

* fact `puppet_sslcert` could be not accessible on newly built server

**Known Issues**