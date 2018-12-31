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
    execute(command, failonfail: fof, override_locale: false, squelch: squelch, combine: combine)
  rescue Puppet::ExecutionFailure => detail
    @resource.fail Puppet::Error, "Could not #{type} #{@resource.ref}: #{detail}", detail
  end

  def configuration_sync
    @property_flush[:configuration]
  end

  def configuration_sync=(value)
    warning _("set @property_flush[:configuration] to #{value}")
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

  def statuscmd
    [command(:compose), '-f', @resource[:path], '-p', @resource[:project], 'ps', @resource[:name]]
  end

  def startcmd
    [command(:compose), '-f', @resource[:path], '-p', @resource[:project], 'up', '-d', '--no-build', @resource[:name]]
  end

  def stopcmd
    [command(:compose), '-f', @resource[:path], '-p', @resource[:project], 'stop', @resource[:name]]
  end

  def restartcmd
    [command(:compose), '-f', @resource[:path], '-p', @resource[:project], 'restart', @resource[:name]]
  end

  def start
    return super unless configuration_sync
    @property_flush[:ensure] = :running
  end

  def stop
    return super unless configuration_sync
    @property_flush[:ensure] = :stopped
  end

  def flush
    warning _("Enter flush with  configuration_sync = \"#{configuration_sync.to_s}\"")
    return if configuration_sync.nil?
    @resource.property(:configuration).sync if configuration_sync
    case status
    when :running
      case @property_flush[:ensure]
      when :running
        restart
      else
        stop
      end
    else
      start if @property_flush[:ensure] == :running
    end
  end
end
