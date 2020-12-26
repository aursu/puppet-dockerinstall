# puppet-dockerinstall
Based on puppetlabs/docker - only installation and service startup for Fedora, CentOS 7 and Ubuntu 14.04

### Usage in profile

Profile `profile::docker` will install Docker daemon and Docker compose and start daemon. It is possible to define `class { 'dockerinstall::config': ... }` in order to override predefined startup options.

```
class profile::docker {
    class { 'dockerinstall': }
    # class {'dockerinstall::config': }
    class { 'dockerinstall::service': }
    class { 'dockerinstall::compose': }
}
```

#### Predefined base profile `dockerinstall::profile::daemon `

This class is base profile which installs Docker and run daemon, installs Docker Compose. It has parameters to setup TLS socket for Docker daemon (listenning on standard port)
