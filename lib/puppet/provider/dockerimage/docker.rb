Puppet::Type.type(:dockerimage).provide(:docker, :parent => Puppet::Provider::Package) do
  desc "Docker image provider"

  # Note: self:: is required here to keep these constants in the context of what will
  # eventually become this Puppet::Type::Package::ProviderDocker class.
  # The query format by which we identify installed images
  self::GO_FORMAT = %Q[{{.ID}} {{.Repository}} {{.Tag}}\\n]
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
      execpipe("#{command(:docker)} image ls --format '#{self::GO_FORMAT}'") { |process|
        # now turn each returned line into a package object
        process.each_line { |line|
          hash = command_to_hash(line)
          images << new(hash) unless hash.empty?
        }
      }
    rescue Puppet::ExecutionFailure
      raise Puppet::Error, _("Failed to list images"), $!.backtrace
    end

    images
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

    [:id, :tag].each { |f| hash[f] = meta[f] }

    path = meta['repository'].split('/')
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