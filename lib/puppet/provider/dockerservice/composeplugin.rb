Puppet::Type.type(:dockerservice).provide(
  :composeplugin,
  # set ini_setting as the parent provider
  :parent => Puppet::Type.type(:dockerservice).provider(:composev2),
) do
  @doc = 'Docker service provider based on Docker Compose plugin'

  commands docker: 'docker'

  # Docker version 27.3.1, build ce12230
  # Supports both old format (v2.x): 'docker compose --version' -> "version 2.40.3"
  # and new format (v5.x): 'docker compose version' -> "Docker Compose version v5.0.2"
  if command('docker')
    confine true: begin
                    # Try new format first (v5+)
                    output = docker('compose', 'version')
                    output.match?(%r{version v[0-9]+\.[0-9]+\.[0-9]+})
                  rescue Puppet::ExecutionFailure
                    # Fall back to old format (v2)
                    begin
                      output = docker('compose', '--version')
                      output.match?(%r{version [0-9]+\.[0-9]+\.[0-9]+})
                    rescue Puppet::ExecutionFailure
                      false
                    end
                  end
  end

  def version
    @version ||= begin
                   # Try new format first (v5+): "Docker Compose version v5.0.2"
                   output = docker('compose', 'version')
                   output[%r{version v([0-9]+\.[0-9]+\.[0-9]+)}, 1]
                 rescue Puppet::ExecutionFailure
                   # Fall back to old format (v2): "version 2.40.3"
                   output = docker('compose', '--version')
                   output[%r{version ([0-9]+\.[0-9]+\.[0-9]+)}, 1]
                 end
  end

  # Don't support them specifying runlevels; always use the runlevels
  # in the init scripts.
  def reload
    build_flag = if @resource.build?
                   '--build'
                 else
                   '--no-build'
                 end
    docker('compose', '-f', @resource[:path], '-p', @resource[:project], 'up', '-d', build_flag, @resource[:name])
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not reload service: #{detail}", detail.backtrace
  end

  def statuscmd
    [command(:docker), 'compose', '-f', @resource[:path], '-p', @resource[:project], 'ps', @resource[:name]]
  end

  def startcmd
    build_flag = if @resource.build?
                   '--build'
                 else
                   '--no-build'
                 end
    [command(:docker), 'compose', '-f', @resource[:path], '-p', @resource[:project], 'up', '-d', build_flag, @resource[:name]]
  end

  def stopcmd
    [command(:docker), 'compose', '-f', @resource[:path], '-p', @resource[:project], 'stop', @resource[:name]]
  end
end
