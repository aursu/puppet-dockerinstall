Puppet::Type.type(:dockerimage).provide(:docker, :parent => Puppet::Provider::Package) do
  @doc = "Docker image provider"

  mk_resource_methods

  # Note: self:: is required here to keep these constants in the context of what will
  # eventually become this Puppet::Type::Package::ProviderDocker class.
  # The query format by which we identify installed images
  self::GO_FORMAT = %Q[{{.ID}} {{.Repository}} {{.Tag}}]
  self::GO_FIELDS = [:id, :path, :tag]

  commands :docker => "docker"

  if command('docker')
    confine :true => begin
      docker('--version')
      rescue Puppet::ExecutionFailure
        false
      else
        true
      end
  end

  def self.instances
    images = []

    # list out all of the packages
    begin
      ls { |pipe|
        Puppet.info _("Got piped content: %{pipe}") % { pipe: pipe }
        # now turn each returned line into a package object
        pipe.each_line { |line|
          hash = command_to_hash(line)
          images << new(hash) unless hash.empty?
        }
      }
    rescue Puppet::ExecutionFailure
      raise Puppet::Error, _("Failed to list images"), $!.backtrace
    end

    images
  end

  def imagename
    name = @resource[:path]
    if @resource[:tag]
      name += ':' + @resource[:tag]
    end
    if @resource[:domain]
      prefix = @resource[:domain] + '/'
      name = prefix + name if name.index(prefix) != 0
    end
    name
  end

  def image
    @image ||= imagename
  end

  def pull
    begin
      output = docker('pull', image)
    rescue
      raise Puppet::Error, "Could not pull #{image}: #{output}", $!.backtrace
    end
  end

  def rmi
    begin
      output = docker('rmi', image)
    rescue
      raise Puppet::Error, "Could not remove image #{image}: #{output}", $!.backtrace
    end
  end

  def self.ls(*args, &block)
    execpipe([command(:docker), 'image', 'ls', '--format', self::GO_FORMAT] + args, &block)
  end

  def ls(*args, &block)
    self.ls(*args, &block)
  end

  def exists?
    !ls(image).empty?
  end

  private
  # @param line [String] one line of docker images query information
  # @return [Hash] of image fields parsed from image info
  # or an empty hash if we failed to parse
  # @api private
  def self.command_to_hash(line)
    line.strip!
    hash = {}

    self::GO_FIELDS.zip(line.split) { |f, v| hash[f] = v }

    pp = hash[:path].split('/')
    if pp.count == 3 || pp[0].match?(%r{:\d+$})
      hash[:domain] = pp[0]
    end

    hash[:name] = hash[:path] + ':' + hash[:tag]
    hash[:provider] = self.name
    hash[:ensure] = :present

    return hash
  end
end