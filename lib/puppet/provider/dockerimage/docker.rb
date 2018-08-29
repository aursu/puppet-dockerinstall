Puppet::Type.type(:dockerimage).provide(:docker, :parent => Puppet::Provider::Package) do
  desc "Docker image provider"

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
      # docker image ls --format "{{.ID}}: {{.Repository}} {{.Tag}}"
      execpipe("#{command(:rpm)} -qa #{nosignature} #{nodigest} --qf '#{self::NEVRA_FORMAT}'") { |process|
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

    if match = self::NEVRA_REGEX.match(line)
      self::NEVRA_FIELDS.zip(match.captures) { |f, v| hash[f] = v }
      hash[:provider] = self.name
      hash[:ensure] = "#{hash[:version]}-#{hash[:release]}"
      hash[:ensure].prepend("#{hash[:epoch]}:") if hash[:epoch] != '0'
    else
      Puppet.debug("Failed to match rpm line #{line}")
    end

    return hash
  end


end