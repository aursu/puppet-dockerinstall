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