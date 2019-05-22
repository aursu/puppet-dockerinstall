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
    include dockerinstall::params
    $rundir = $dockerinstall::params::compose_rundir

    unless '/' in $title {
        fail('Composeservice title must be in format <project name>/<service name>')
    }

    if $project_directory {
        $basedir = dirname($project_directory)
    }
    elsif $project_basedir {
        $basedir = $project_basedir
    }
    else {
        $basedir = $rundir
    }

    if $project_directory {
        $project = $project_directory
    }
    elsif $project_name {
        $project = $project_name
    }
    else {
        $titledata = split($title, '/')
        $project = $titledata[0]
    }

    if $configuration_path {
        $path = dirname($configuration_path)
    }
    elsif $project_directory {
        $path = $project_directory
    }
    else {
        $path = "${basedir}/${project}"
    }

    unless $basedir in ['/run', '/var/run', '/lib', '/var/lib', $rundir] or defined(File[$basedir]) {
        file { $basedir:
            ensure => 'directory',
            force  => true,
        }
    }

    if $project_basedir {
        unless $project_basedir in ['/run', '/var/run', '/lib', '/var/lib', $rundir, $basedir] or
               defined(File[$project_basedir]) {
            file { $project_basedir:
                ensure => 'directory',
                force  => true,
            }
        }
    }

    unless $path in ['/run', '/var/run', '/lib', '/var/lib', $rundir, $basedir] or defined(File[$path]) {
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
