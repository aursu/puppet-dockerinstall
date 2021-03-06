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

### `Dockerservice` custom type paths description

#### `project`

  1) default value is project name from `title_patterns`
     therefore this field will not be empty

  2) if `project` provided:
    - it must be either project name or
    - absolute path to the project directory (root of the project)

  3) if absolute path provided
    - it will be transformed to project name (base name of the path) and
    - `basedir` parameter will be set to base directory (dirname) of project
      path therefore
    - catalog must include according `File` resource for this
      dirname;
    - but parameter `basedir` will have value of *specified* for this
      parameter path

#### `basedir`

  1) default value is either /run/compose or /var/run/compose
  2) must be absolute path if provided
  3) catalog must include according File resource

#### `path`

  1) default to `docker-compose.yml`
  2) if provided and it is absolute path:
    - `project` parameter must not be absolute path as well
    - catalog must contain File resource of directory for specified file path
  3) if provided and it is relative path
    - it will be transformed to <basedir>/<project>/<path>