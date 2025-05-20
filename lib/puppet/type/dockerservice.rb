require 'yaml'
require 'puppet/parameter/boolean'

Puppet::Type.newtype(:dockerservice, self_refresh: true) do
  @doc = 'Docker Compose service'
  #
  class DockerserviceParam < Puppet::Parameter
    attr_reader :should

    munge do |value|
      @should = value
      value
    end

    validate do |value|
      raise Puppet::Error, '%{name} must be a string' % { name: name.capitalize } unless value.is_a?(String)
      raise Puppet::Error, '%{name} must be a non-empty string' % { name: name.capitalize } if value.empty?
    end
  end

  # Handle whether the service should actually be running right now.
  newproperty(:ensure) do
    desc 'Whether a service should be running.'

    newvalue(:stopped, :event => :service_stopped) do
      provider.stop
    end

    newvalue(:running, :event => :service_started, :invalidate_refreshes => true) do
      provider.start
    end

    aliasvalue(:false, :stopped)
    aliasvalue(:true, :running)

    def retrieve
      config_sync
      provider.status
    end

    def insync?(current)
      # skip resource ensure property sync if configuration is not in sync
      return true if provider.configuration_sync
      super(current)
    end

    def config_sync
      property = @resource.property(:configuration)
      current = property.retrieve
      # set provider to sync configuration
      provider.configuration_sync = true unless property.safe_insync?(current)
    end
  end

  def self.title_patterns
    [
      [
        %r{^([-\w]+)/([-\w]+)$},
        [
          [:project],
          [:name],
        ],
      ],
    ]
  end

  newparam(:project, namevar: true, :parent => DockerserviceParam) do
    desc 'Docker Compose project name. It could be absolute path to a project
      directory or just alternate project name'

    validate do |value|
      super(value)
      if value.include?('/')
        raise Puppet::Error, 'Project path must be absolute' unless Puppet::Util.absolute_path?(value)
      end
    end

    munge do |value|
      super(value)
      if Puppet::Util.absolute_path?(value)
        # project directory could override basedir
        resource[:basedir] = File.dirname(value)
        File.basename(value)
      else
        value
      end
    end
  end

  newparam(:name, namevar: true) do
    desc 'Docker compose service name'

    validate do |value|
      raise Puppet::Error, _('name must not contain whitespaces: %{name}') % { name: value } if value.index(%r{\s})
    end
  end

  newparam(:basedir, :parent => DockerserviceParam) do
    desc 'The directory where to store Docker Compose projects (it could be
      runtime or temporary directory). By default /var/run/compose'

    # provider has a check for /run directory
    defaultto { provider.class.basedir if provider.class.respond_to?(:basedir) }

    validate do |value|
      super(value)
      path = resource.fixpath(value)
      raise Puppet::Error, 'Basedir must be absolute' unless Puppet::Util.absolute_path?(path)

      # fail if base directory is not in catalog
      raise 'File resource for base directory %{path} not found' % { path: path } unless @resource.catalog.resource(:file, path)
    end

    munge do |value|
      # normalize path
      resource.fixpath(value)
    end
  end

  newparam(:path, :parent => DockerserviceParam) do
    desc 'Path to Docker Compose configuration file. Path should be
      absolute or relative to Project directory'

    defaultto 'docker-compose.yml'

    attr_reader :dirname

    validate do |value|
      super(value)
      # both project and path could not be absolute

      if Puppet::Util.absolute_path?(value)
        project = @resource.parameter(:project).should
        if Puppet::Util.absolute_path?(project)
          raise Puppet::Error, "Path should be relative to project directory (#{project}) - not absolute"
        end

        @dirname = resource.fixpath(File.dirname(value))
        raise 'File resource for configuration base path %{path} not found' % { path: dirname } unless @resource.catalog.resource(:file, dirname)
      end
    end

    munge do |value|
      path = resource.fixpath(value)
      if Puppet::Util.absolute_path?(path)
        path
      else
        File.join(@resource[:basedir], @resource[:project], path)
      end
    end
  end

  newproperty(:configuration) do
    include Puppet::Util::Checksums

    attr_reader :actual_content

    desc 'Docker Compose configuration file content (YAML)'

    def retrieve
      path = @resource[:path]
      s = stat(path)
      return nil unless s && s.ftype == 'file'

      begin
        '{sha256}' + sha256_file(path).to_s
      rescue => detail
        raise Puppet::Error, "Could not read file #{resource.title}: #{detail}", detail.backtrace
      end
    end

    validate do |value|
      raise Puppet::Error, 'Configuration must be a string' unless value.is_a?(String)
      raise Puppet::Error, 'Configuration must be a non-empty string' if value.empty?
      provider.configuration_validate(value) if provider.respond_to?(:configuration_validate)
    end

    munge do |value|
      @actual_content = value
      '{sha256}' + sha256(@actual_content)
    end

    # Checksums need to invert how changes are printed.
    def change_to_s(is, want)
      return "defined configuration as '#{want}'" if is == :absent
      return "undefined configuration from '#{is}'" if want == :absent
      "configuration changed '#{is}' to '#{want}'"
    end

    def insync?(is)
      return false if is.nil?
      return true unless resource.replace?
      super(is)
    end

    def sync
      event = stat ? :configuration_changed : :configuration_created

      mode_int = 0o0644
      File.open(@resource[:path], 'wb', mode_int) { |f| write(f) }
      # configuration synced here - no need to sync it elsewhere
      provider.configuration_sync = false

      event
    end

    def write(file)
      checksum = sha256_stream do |sum|
        sum << actual_content
        file.print(actual_content)
      end
      "{sha256}#{checksum}"
    end

    def stat(path = nil)
      path = @resource[:path] if path.nil?
      Puppet::FileSystem.stat(path)
    rescue Errno::ENOENT
      nil
    rescue Errno::ENOTDIR
      nil
    rescue Errno::EACCES
      warning _('Could not stat; permission denied')
      nil
    end
  end

  newparam(:status) do
    desc 'Specify a *status* command manually. This command must
      return 0 if the service is running and a nonzero value otherwise.'
  end

  newparam(:restart) do
    desc 'Specify a *restart* command manually.'
  end

  newparam(:start) do
    desc 'Specify a *start* command manually.'
  end

  newparam(:stop) do
    desc 'Specify a *stop* command manually.'
  end

  # requirements: Docker compose file with 'build' and 'image' parameters
  # 'build' parameter have to contain 'context' parameter and optionally 'dockerfile'
  newparam(:build, boolean: true, parent: Puppet::Parameter::Boolean) do
    desc 'Specify whether to build Docker image'

    defaultto :false
  end

  newparam(:replace, boolean: true, parent: Puppet::Parameter::Boolean) do
    desc 'Whether to replace a configuration file or not'

    defaultto :true
  end

  autorequire(:file) do
    req = []
    req << self[:basedir] if self[:basedir]

    confbase = @parameters[:path].dirname
    req << confbase if confbase
    req
  end

  validate do
    provider.configuration_integrity if provider.respond_to?(:configuration_integrity)
  end

  def configuration
    @parameters[:configuration].actual_content
  end

  def fixpath(value)
    path =  if value.include?('/')
              File.join(File.split(value))
            else
              value
            end
    return File.expand_path(path) if Puppet::Util.absolute_path?(path)
    path
  end

  # Basically just a synonym for restarting.  Used to respond
  # to events.
  def refresh
    # Only restart if we're actually running
    if (@parameters[:ensure] || newattr(:ensure)).retrieve == :running
      provider.restart
    else
      debug 'Skipping restart; service is not running'
    end
  end
end
