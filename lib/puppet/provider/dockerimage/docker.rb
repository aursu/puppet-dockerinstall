Puppet::Type.type(:dockerimage).provide(:docker, parent: Puppet::Provider::Package) do
  @doc = 'Docker image provider'

  mk_resource_methods

  # Note: self:: is required here to keep these constants in the context of what will
  # eventually become this Puppet::Type::Package::ProviderDocker class.
  # The query format by which we identify installed images
  self::GO_FORMAT = %({{.ID}} {{.Repository}} {{.Tag}}).freeze
  self::GO_FIELDS = [:id, :path, :tag].freeze

  commands docker: 'docker'

  if command('docker')
    confine true: begin
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
      execpipe(lscmd) do |pipe|
        # now turn each returned line into a package object
        pipe.each_line do |line|
          hash = command_to_hash(line)
          images << new(hash) unless hash.empty?
        end
      end
    rescue Puppet::ExecutionFailure
      raise Puppet::Error, _('Failed to list images'), $ERROR_INFO.backtrace
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
      image = prefix + image unless image.index(prefix).zero?
    end
    image
  end

  def image
    @image ||= imagename
  end

  def pull
    output = docker('pull', image)
  rescue Puppet::ExecutionFailure
    raise Puppet::Error, "Could not pull #{image}: #{output}", $ERROR_INFO.backtrace
  end

  def rmi
    output = docker('rmi', image)
  rescue Puppet::ExecutionFailure
    raise Puppet::Error, "Could not remove image #{image}: #{output}", $ERROR_INFO.backtrace
  end

  def self.lscmd(*args)
    ([command(:docker), 'image', 'ls', '--format', "'#{self::GO_FORMAT}'"] + args).join(' ')
  end

  def lscmd(*args)
    self.class.lscmd(*args)
  end

  def exists?
    return !execute(lscmd(image)).empty? if @resource[:domain]
    # if image was not prefetched @property_hash is empty hash
    @property_hash[:ensure] == :present
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

    hash[:name] = hash[:path] + ':' + hash[:tag]
    hash[:provider] = name
    hash[:ensure] = :present

    hash
  end
end
