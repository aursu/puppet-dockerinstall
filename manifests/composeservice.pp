# A description of what this defined type does
#
# @summary A short summary of the purpose of this defined type.
#
# @example
#   dockerinstall::composeservice { 'namevar': }
define dockerinstall::composeservice (
    String  $configuration,
    Variant[
        Enum['stopped', 'running'],
        Boolean
    ]       $ensure             = 'running',
    Optional[String]
            $project_name       = undef,
    Optional[Stdlib::Unixpath]
            $project_directory  = undef,
    Optional[Stdlib::Unixpath]
            $project_basedir    = undef,
    Optional[Stdlib::Unixpath]
            $configuration_path = undef,
)
{
    unless '/' in $title {
        fail('Composeservice title must be in format <project name>/<service name>')
    }

    if $project_basedir {
        $basedir = $project_basedir
    }
    elsif $project_directory {
        $basedir = dirname($project_directory)
    }
    else {
        include dockerinstall::params
        $basedir = $dockerinstall::params::compose_rundir
    }

    if $configuration_path {
        $project = $project_directory
        $path = dirname($configuration_path)
    }
    elsif $project_directory {
        $project = $project_directory
        $path = $project_directory
    }
    else {
        if $project_name {
            $project = $project_name
        }
        else {
            $titledata = split($title, '/')
            $project = $titledata[0]
        }
        $path = $basedir + '/' + $project
    }

    unless $basedir in ['/run', '/var/run', '/lib', '/var/lib', '/run/compose', '/var/run/compose'] {
        file { $basedir:
            ensure => 'directory',
            force  => true,
        }
    }

    unless $path in ['/run', '/var/run', '/lib', '/var/lib', '/run/compose', '/var/run/compose', $basedir] {
        file { $path:
            ensure => 'directory',
            force  => true,
        }
    }

    dockerservice { $title:
        ensure        => $ensure,
        configuration => $configuration,
        basedir       => $project_basedir,
        project       => $project,
        path          => $configuration_path,
    }
}
