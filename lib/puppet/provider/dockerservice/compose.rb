$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet_x/dockerinstall'

Puppet::Type.type(:dockerservice).provide(
  :compose,
  # set ini_setting as the parent provider
  :parent => Puppet::Type.type(:service).provider(:base),
) do
  @doc = 'Docker service provider'

  # Delegate to helper module
  # Child providers inherit this method
  def self.basedir
    PuppetX::Dockerinstall.default_basedir
  end

  commands compose: 'docker-compose'

  if command('compose')
    confine true: begin
                    compose('--version')
                  rescue Puppet::ExecutionFailure
                    false
                  else
                    compose('--version').match?(%r{version 1\.[0-9]+\.[0-9]+})
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

  def version
    @version ||= compose('--version')[%r{version v?([0-9]+\.[0-9]+\.[0-9]+)}, 1]
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
end
