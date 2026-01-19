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

  # Parse YAML configuration with error handling
  # Helper method to centralize YAML parsing logic
  #
  # @param config_content [String] YAML content to parse
  # @return [Hash] Parsed YAML data
  # @raise [Puppet::Error] if YAML syntax is invalid
  def self.parse_yaml_safe(config_content)
    YAML.safe_load(config_content)
  rescue YAML::SyntaxError => e
    raise Puppet::Error, "Unable to parse YAML: #{e.message}"
  end

  # Validate YAML configuration syntax and structure
  # Used by provider's configuration property validation
  #
  # @param config_content [String] YAML content to validate
  # @param confpath [String] Path to configuration file (for error messages)
  # @return [void]
  # @raise [Puppet::Error] if YAML is invalid
  def self.validate_yaml_syntax(config_content, confpath)
    data = parse_yaml_safe(config_content)
    raise Puppet::Error, "#{confpath}: file does not contain a valid yaml hash" unless data.is_a?(Hash)
  end

  # Get service configuration from parsed YAML data
  # Helper method to retrieve and validate service existence
  #
  # @param data [Hash] Parsed YAML data
  # @param service_name [String] Name of the service to retrieve
  # @return [Hash] Service configuration
  # @raise [Puppet::Error] if service doesn't exist in configuration
  def self.get_service(data, service_name)
    unless data['services']&.include?(service_name)
      raise Puppet::Error, "Service #{service_name} does not exist in configuration file"
    end
    data['services'][service_name]
  end

  # Validate basic build configuration (image + build parameters)
  # Helper method to check build configuration structure
  #
  # @param service [Hash] Service configuration from docker-compose
  # @return [Hash, String] Build configuration
  # @raise [Puppet::Error] if build configuration is invalid
  def self.validate_build_config(service)
    build_config = service['build']
    unless service['image'] && build_config
      raise Puppet::Error, "Service definition should contain 'image' and 'build' parameters"
    end

    if build_config.is_a?(Hash) && !build_config['context']
      raise Puppet::Error, "Service 'build' parameter should contain 'context' parameter"
    end

    build_config
  end

  # Validate build context path
  # Used by provider during configuration integrity check
  #
  # @param build [Hash, String] Build configuration from docker-compose
  # @param confpath [String] Path to docker-compose.yml file
  # @return [void]
  # @raise [Puppet::Error] if build context is invalid
  def self.validate_build_context(build, confpath)
    confdir = File.dirname(confpath)
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
    data = parse_yaml_safe(config_content)
    service = get_service(data, service_name)

    return unless build_enabled

    build = validate_build_config(service)
    validate_build_context(build, confpath)
  end
end