Puppet::Type.type(:dockerimage).provide(:docker, :parent => Puppet::Provider::Package) do
  @doc = "Docker image provider"

  # Note: self:: is required here to keep these constants in the context of what will
  # eventually become this Puppet::Type::Package::ProviderDocker class.
  # The query format by which we identify installed images
  self::GO_FORMAT = %Q[{{.ID}} {{.Repository}} {{.Tag}}]
  self::GO_FIELDS = [:id, :repository, :tag]

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
      execpipe("#{command(:docker)} image ls --format '#{self::GO_FORMAT}'") { |pipe|
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
    image = @resource[:path]
    if @resource[:tag]
      image += ':' + @resource[:tag]
    end
    if @resource[:domain]
      prefix = @resource[:domain] + '/'
      image = prefix + image if !image.include?(prefix)
    end
    image
  end

  def pull
    image = imagename
    begin
      output = docker('pull', image)
    rescue
      raise Puppet::Error, "Could not pull #{image}: #{output}", $!.backtrace
    end
  end

  def rmi
    image = imagename
    begin
      output = docker('rmi', image)
    rescue
      raise Puppet::Error, "Could not remove image #{image}: #{output}", $!.backtrace
    end
  end

  private
  # @param line [String] one line of docker images query information
  # @return [Hash] of image fields parsed from image info
  # or an empty hash if we failed to parse
  # @api private
  def self.command_to_hash(line)
    line.strip!
    hash = {}
    meta = self::GO_FIELDS.zip(line.split)

    meta.each { |f, v| hash[f] = v if [:id, :tag].include?(f)}

    path = meta[:repository].split('/')
    if path.count == 3
      hash[:domain] = path[0]
      hash[:path] = path[1] + '/' + path[2]
    else
      hash[:path] = meta['repository']
    end

    hash[:provider] = self.name
    hash[:ensure] = :present

    return hash
  end
end