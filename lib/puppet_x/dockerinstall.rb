# frozen_string_literal: true

require 'yaml'

unless defined?(PuppetX)
  # Top-level namespace for Puppet extensions.
  # This namespace is used by Puppet modules to extend Puppet functionality.
  module PuppetX
  end
end

# Shared utilities for the dockerinstall module.
# Provides common helper methods used by both custom types and providers.
module PuppetX::Dockerinstall
  # Determine default basedir based on system
  # Used by both type and providers
  #
  # @return [String] '/run/compose' if /run directory exists, otherwise '/var/run/compose'
  def self.default_basedir
    if File.directory?('/run')
      '/run/compose'
    else
      '/var/run/compose'
    end
  end

  # Validate build requirements in service configuration
  # Used by type during resource validation
  #
  # @param config_content [String] YAML content of docker-compose configuration
  # @param service_name [String] Name of the service to validate
  # @return [void]
  # @raise [Puppet::Error] if build configuration is invalid
  def self.validate_build_requirements(config_content, service_name)
    data = YAML.safe_load(config_content)
    service = data['services'][service_name] if data['services']

    return unless service

    build_config = service['build']
    unless service['image'] && build_config
      raise Puppet::Error, "Service definition should contain 'image' and 'build' parameters"
    end

    if build_config.is_a?(Hash) && !build_config['context']
      raise Puppet::Error, "Service 'build' parameter should contain 'context' parameter"
    end
  rescue YAML::SyntaxError => e
    raise Puppet::Error, "Invalid YAML syntax: #{e.message}"
  end

  # Validate build context path
  # Used by provider during configuration integrity check
  #
  # @param build [Hash, String] Build configuration from docker-compose
  # @param confdir [String] Directory containing docker-compose.yml
  # @return [void]
  # @raise [Puppet::Error] if build context is invalid
  def self.validate_build_context(build, confdir)
    context = build['context']
    context_path = nil

    raise Puppet::Error, "Service 'build' parameter should contain 'context' parameter" unless context

    case context
    # when context is URL - git repositories and URLs to tarball are supported
    when %r{^https?://}
      # https://docs.docker.com/engine/reference/commandline/build/#git-repositories
      # https://docs.docker.com/engine/reference/commandline/build/#tarball-contexts
      unless context.match?(%r{\.git(#.+)?$})
        raise Puppet::Error, 'Docker build context must be valid Git repo URL'
      end
    when %r{^/}
      context_path = context
    else
      context_path = File.join(confdir, context)
    end

    return unless context_path
    return if Puppet::Util.absolute_path?(context_path)

    raise Puppet::Error, "Context path must be absolute, not #{context_path}"
  end

  # Complete configuration integrity validation
  # Used by provider during prefetch/exists?/create
  #
  # @param config_content [String] YAML content of docker-compose configuration
  # @param service_name [String] Name of the service to validate
  # @param confpath [String] Path to docker-compose.yml file
  # @param build_enabled [Boolean] Whether build is enabled for this service
  # @return [void]
  # @raise [Puppet::Error] if configuration is invalid
  def self.validate_configuration_integrity(config_content, service_name, confpath, build_enabled)
    data = YAML.safe_load(config_content)

    # error if service does not exist in docker-compose yaml
    unless data['services'] && data['services'].include?(service_name)
      raise Puppet::Error, "Service #{service_name} does not exist in configuration file"
    end

    return unless build_enabled

    service = data['services'][service_name]
    build = service['build']

    raise Puppet::Error, "Service definition should contain 'image' and 'build' parameters" unless service['image'] && build

    confdir = File.dirname(confpath)
    validate_build_context(build, confdir)
  rescue YAML::SyntaxError => e
    raise Puppet::Error, "Unable to parse #{e.message}"
  end

  # Validate YAML configuration syntax and structure
  # Used by provider's configuration property validation
  #
  # @param config_content [String] YAML content to validate
  # @param confpath [String] Path to configuration file (for error messages)
  # @return [void]
  # @raise [Puppet::Error] if YAML is invalid
  def self.validate_yaml_syntax(config_content, confpath)
    data = YAML.safe_load(config_content)
    raise Puppet::Error, "#{confpath}: file does not contain a valid yaml hash" unless data.is_a?(Hash)
  rescue YAML::SyntaxError => e
    raise Puppet::Error, "Unable to parse #{e.message}"
  end
end
