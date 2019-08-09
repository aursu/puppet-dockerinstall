require 'yaml'

Puppet::Functions.create_function(:'dockerinstall::cidr_network') do
  dispatch :cidr_network do
    param 'Stdlib::IP::Address', :cidr
  end

  def cidr_network(cidr)
    IPAddr.new(cidr).to_s
  end
end
