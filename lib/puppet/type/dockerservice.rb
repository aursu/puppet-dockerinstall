require 'yaml'

Puppet::Type.newtype(:dockerservice) do
  @doc = 'Docker Compose service'

  class DockerserviceParam < Puppet::Parameter
    attr_reader :should

    munge do |value|
      @should = value
    end

    validate do |value|
      fail Puppet::Error, '%{name} must be a string' % {name: self.name.capitalize} unless value.is_a?(String)
      fail Puppet::Error, '%{name} must be a non-empty string' % {name: self.name.capitalize} if value.empty?
    end
  end

  # Handle whether the service should actually be running right now.
  newproperty(:ensure) do
    desc 'Whether a service should be running.'

    newvalue(:stopped, :event => :service_stopped) do # rubocop:disable Style/HashSyntax
      provider.stop
    end

    newvalue(:running, :event => :service_started, :invalidate_refreshes => true) do # rubocop:disable Style/HashSyntax
      provider.start
    end

    aliasvalue(:false, :stopped)
    aliasvalue(:true, :running)

    def retrieve
      config_sync
      provider.status
    end

    def sync
      config_sync
      super
    end

    def config_sync
      if property = @resource.property(:configuration)
        val = property.retrieve
        property.sync unless property.safe_insync?(val)
      end
    end

  end

  def self.title_patterns
    [
      [
        %r{^([-\w]+)/([\w]+)$},
        [
          [:project],
          [:name]
        ]
      ]
    ]
  end

  newparam(:project, namevar: true, :parent => DockerserviceParam) do
    desc 'Docker Compose project name. It could be absolute path to a project
      directory or just alternate project name'

    attr_reader :should

    validate do |value|
      super(value)
      if value.include?('/')
        fail Puppet::Error, 'Path must be absolute' unless Puppet::Util.absolute_path?(value)
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
      fail Puppet::Error, _('name must not contain whitespaces: %{name}') % {name: value} if value.match(%r{\s})
    end
  end

  newparam(:basedir, :parent => Puppet::Parameter::Path) do # rubocop:disable Style/HashSyntax
    desc 'The directory where to store Docker Compose projects (it could be
      runtime or temporary directory). By default /var/run/compose'

    # parent is  Puppet::Parameter::Path which accepts String or Array
    # we do not need Array here.
    accept_arrays(false)

    # provider has a check for /run directory
    defaultto { provider.class.basedir if provider.class.respond_to?(:basedir) }

    munge do |value|
      # normalize path
      File.join(File.split(File.expand_path(value)))
    end
  end

  newparam(:path, :parent => DockerserviceParam) do
    desc 'Path to Docker Compose configuration file. Path should be
      absolute or relative to Project directory'

    defaultto 'docker-compose.yml'

    validate do |value|
      super(value)
      # both project and path could not be absolute
      project = @resource.parameter(:project).should
      if Puppet::Util.absolute_path?(value) && Puppet::Util.absolute_path?(project)
        fail Puppet::Error,
              "Path should be relative to project directory (#{project}) - not absolute"
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
      return nil unless (s = stat(path) && s.ftype == 'file')

      begin
        '{sha256}' + sha256_file(path).to_s
      rescue => detail
        raise Puppet::Error, "Could not read file #{resource.title}: #{detail}", detail.backtrace
      end
    end

    validate do |value|
      fail Puppet::Error, 'Configuration must be a string' unless value.is_a?(String)
      fail Puppet::Error, 'Configuration must be a non-empty string' if value.empty?
      begin
        data = YAML.safe_load(value)
        fail Puppet::Error, _('%{path}: file does not contain a valid yaml hash') % { path: @resource[:path] } unless data.is_a?(Hash)
      rescue YAML::SyntaxError => ex
        raise Puppet::Error, _("Unable to parse #{ex.message}")
      end
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

    def sync
      mode_int = 0o0644
      File.open(@resource[:path], 'wb', mode_int) { |f| write(f) }
    end

    def write(file)
      checksum = sha256_stream do |sum|
        sum << actual_content
        file.print actual_content
      end
      "{sha256}#{checksum}"
    end

    def stat(path)
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
    desc "Specify a *status* command manually. This command must
      return 0 if the service is running and a nonzero value otherwise."
  end

  autorequire(:file) do
    self[:basedir] if self[:basedir]
  end

  validate do
    data = YAML.safe_load(@parameters[:configuration].actual_content)
    fail 'Service %{name} does not exist in configuration file' % {name: self[:name]} unless data['services'] and data['services'].include?(self[:name])
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
end
