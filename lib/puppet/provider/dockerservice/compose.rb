Puppet::Type.type(:dockerservice).provide(
  :compose,
  # set ini_setting as the parent provider
  :parent => Puppet::Type.type(:service).provider(:base), # rubocop:disable Style/HashSyntax
) do
  @doc = 'Docker service provider'

  def self.basedir
    if File.directory?('/run')
      '/run/compose'
    else
      '/var/run/compose'
    end
  end

  commands compose: 'docker-compose'

  if command('compose')
    confine true: begin
                    compose('--version')
                  rescue Puppet::ExecutionFailure
                    false
                  else
                    true
                  end
  end

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  def texecute(type, command, fof = true, squelch = false, combine = true)
    execute(command,  failonfail: fof, override_locale: false, squelch: squelch, combine: combine,
                      custom_environment: { 'COLUMNS' => '512' })
  rescue Puppet::ExecutionFailure => detail
    @resource.fail Puppet::Error, "Could not #{type} #{@resource.ref}: #{detail}", detail
  end

  def configuration_sync
    @property_flush[:configuration]
  end

  def configuration_sync=(value)
    @property_flush[:configuration] = value
  end

  def status
    return :stopped if configuration_sync
    # Don't fail when the exit status is not 0.
    output = ucommand(:status, false)
    if output
      services = output.split(%r{\n}).select { |l| l.start_with?("#{@resource[:project]}_#{@resource[:name]}_") }
      services.each do |l|
        m = %r{\s+(Paused|Restarting|Ghost|Up( \(.+\))?|Exit [-0-9]+)\s+}.match(l)
        return :running if m[1].include?('Up')
      end
    end
    :stopped
  end

  # Don't support them specifying runlevels; always use the runlevels
  # in the init scripts.
  def reload
    build_flag = if @resource.build?
                   '--build'
                 else
                   '--no-build'
                 end
    compose('-f', @resource[:path], '-p', @resource[:project], 'up', '-d', build_flag, @resource[:name])
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not reload service: #{detail}", detail.backtrace
  end

  def statuscmd
    [command(:compose), '-f', @resource[:path], '-p', @resource[:project], 'ps', @resource[:name]]
  end

  def startcmd
    build_flag = if @resource.build?
                   '--build'
                 else
                   '--no-build'
                 end
    [command(:compose), '-f', @resource[:path], '-p', @resource[:project], 'up', '-d', build_flag, @resource[:name]]
  end

  def stopcmd
    [command(:compose), '-f', @resource[:path], '-p', @resource[:project], 'stop', @resource[:name]]
  end

  # If there are existing containers for a service, and the service’s
  # configuration or image was changed after the container’s creation, docker-
  # compose up picks up the changes by stopping and recreating the containers
  # (preserving mounted volumes). To prevent Compose from picking up changes,
  # use the --no-recreate flag.
  def restartcmd
    startcmd
  end

  def flush
    # nothing to flush if configuration is in sync
    return if configuration_sync.nil?
    case status
    when :running
      case @resource[:ensure]
      when :running
        restart
      else
        stop
      end
    else
      start if @resource[:ensure] == :running
    end
  end

  def configuration_validate(value)
    data = YAML.safe_load(value)
    raise Puppet::Error, _('%{path}: file does not contain a valid yaml hash') % { path: @resource[:path] } unless data.is_a?(Hash)
  rescue YAML::SyntaxError => e
    raise Puppet::Error, _("Unable to parse #{e.message}")
  end

  def docker_build_validate(build)
    confpath = @resource[:path]
    confdir  = File.dirname(confpath)

    context = build['context']
    dockerfile = build['dockerfile'] || 'Dockerfile'
    context_path = nil

    raise Puppet::Error, "Service 'build' parameter should contain 'context' parameter" unless context

    case context
    # when context is URL - git repositories and URLs to tarball are supported
    when %r{^https?://}
      # https://docs.docker.com/engine/reference/commandline/build/#git-repositories
      # https://docs.docker.com/engine/reference/commandline/build/#tarball-contexts
      unless context =~ %r{\.git(#.+)?$} # || context =~ %r{(tgz|tar\.(gz|bz2|xz))$}
        raise 'Docker build context must be either valid Git repo URL or URL to tarball file (tar.gz|tar.bz2|tar.xz)'
      end
    when %r{^/}
      context_path = context
    else
      context_path = File.join(confdir, context)
    end

    return unless context_path

    # if context =~ %r{(tgz|tar\.(gz|bz2|xz))$}
    #   raise Puppet::Error, "Docker build context tarball does not exist: #{context_path}" unless File.exist?(context_path)
    # else
    raise Puppet::Error, "Docker build context directory does not exist: #{context_path}" unless File.directory?(context_path)
    dockerfile_path = File.join(context_path, dockerfile)

    raise Puppet::Error, "Docker file could not be found: #{dockerfile_path}" unless File.exist?(dockerfile_path)
    # end
  end

  def configuration_integrity
    name     = @resource[:name]
    data     = YAML.safe_load(resource.configuration)

    # error if service does not exist in docker-compose yaml
    raise 'Service %{name} does not exist in configuration file' % { name: name } unless data['services'] && data['services'].include?(name)

    service = data['services'][name]
    build = service['build']

    return unless @resource.build?

    raise Puppet::Error, "Service definition should contain 'image' and 'build' parameters" unless service['image'] && build
    docker_build_validate(build)
  end
end
