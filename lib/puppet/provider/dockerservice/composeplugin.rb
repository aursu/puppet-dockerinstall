Puppet::Type.type(:dockerservice).provide(
  :composeplugin,
  # set ini_setting as the parent provider
  :parent => Puppet::Type.type(:dockerservice).provider(:composev2),
) do
  @doc = 'Docker service provider based on Docker Compose plugin'

  commands docker: 'docker'

  # Docker Compose plugin version detection
  # Command: 'docker compose version' -> "Docker Compose version vX.Y.Z"
  # Works for both v2.x and v5.x plugin versions
  if command('docker')
    confine true: begin
                    output = docker('compose', 'version')
                    output.match?(%r{version v[0-9]+\.[0-9]+\.[0-9]+})
                  rescue Puppet::ExecutionFailure
                    false
                  end
  end

  def version
    @version ||= docker('compose', 'version')[%r{version v([0-9]+\.[0-9]+\.[0-9]+)}, 1]
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
