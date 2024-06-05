# Changelog

All notable changes to this project will be documented in this file.

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

## Release 0.20.0

**Features**

* Added Windows support for private Registries auth (inside user home directory)

**Bugfixes**

**Known Issues**