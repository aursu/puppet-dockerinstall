Puppet::Type.type(:dockerservice).provide(
  :composev2,
  # set ini_setting as the parent provider
  :parent => Puppet::Type.type(:dockerservice).provider(:compose), # rubocop:disable Style/HashSyntax
) do
  @doc = 'Docker service provider based on Docker Compose v2'

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
                    compose('--version').match?(%r{version v2\.[0-9]+\.[0-9]+})
                  end
  end

  def status
    return :stopped if configuration_sync
    # Don't fail when the exit status is not 0.
    output = ucommand(:status, false)
    if output
      services = output.split(%r{\n}).select { |l| l.start_with?("#{@resource[:project]}_#{@resource[:name]}_") }
      services.each do |l|
        # paused | restarting | removing | running | dead | created | exited
        m = %r{\s+(paused|restarting|removing|created|running( \(.+\))?|exited \([-0-9]+\)|dead \([-0-9]+\))\s+}.match(l)
        return :running if m[1].include?('running')
      end
    end
    :stopped
  end
end
