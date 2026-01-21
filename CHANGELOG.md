# Changelog

All notable changes to this project will be documented in this file.

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