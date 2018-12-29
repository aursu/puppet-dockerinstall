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

  def statuscmd
    [command(:compose), '-f', @resource[:path], '-p', @resource[:project], 'ps', @resource[:name]]
  end

  def status
    # Don't fail when the exit status is not 0.
    output = ucommand(:status, false)
    warning _("Status command output: \"#{output}\"")
    if output
      services = output.split(%r{\n}).select { |l| l.start_with?("#{@resource[:project]}_#{@resource[:name]}_") }
      services.each do |l|
        m = %r{\s+(Paused|Restarting|Ghost|Up( \(.+\))?|Exit [-0-9]+)\s+}.match(l)
        return :running if m[1].include?('Up')
      end
    end
    :stopped
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
end
