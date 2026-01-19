# PuppetX::Dockerinstall - shared utilities for dockerinstall module
module PuppetX
  module Dockerinstall
    # Determine default basedir based on system
    # Used by both type and providers
    def self.default_basedir
      if File.directory?('/run')
        '/run/compose'
      else
        '/var/run/compose'
      end
    end
  end
end
