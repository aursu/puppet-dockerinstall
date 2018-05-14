
require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'

begin
  require 'spec_helper_local' if File.file?(File.join(File.dirname(__FILE__), 'spec_helper_local.rb'))
rescue LoadError => loaderror
  warn "Could not require spec_helper_local: #{loaderror.message}"
end

include RspecPuppetFacts

# TODO: http://unethicalblogger.com/2014/03/01/testing-custom-facts-with-rspec.html
#       https://github.com/puppetlabs/puppetlabs-firewall/blob/master/spec/unit/facter/iptables_persistent_version_spec.rb

# https://github.com/mcanevet/rspec-puppet-facts/blob/master/README.md#create-dynamic-facts
# register is_init_systemd fact from module lsys
add_custom_fact :is_init_systemd, ->(os, _facts) do
  if os == 'ubuntu-14.04-x86_64'
    false
  else
    true
  end
end

default_facts = {
  puppetversion: Puppet.version,
  facterversion: Facter.version
}

default_facts_path = File.expand_path(File.join(File.dirname(__FILE__), 'default_facts.yml'))
default_module_facts_path = File.expand_path(File.join(File.dirname(__FILE__), 'default_module_facts.yml'))

if File.exist?(default_facts_path) && File.readable?(default_facts_path)
  default_facts.merge!(YAML.safe_load(File.read(default_facts_path)))
end

if File.exist?(default_module_facts_path) && File.readable?(default_module_facts_path)
  default_facts.merge!(YAML.safe_load(File.read(default_module_facts_path)))
end

RSpec.configure do |c|
  c.default_facts = default_facts
  c.before :each do
    # set to strictest setting for testing
    # by default Puppet runs at warning level
    Puppet.settings[:strict] = :warning
  end
end
