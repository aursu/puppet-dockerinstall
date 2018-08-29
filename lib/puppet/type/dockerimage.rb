Puppet::Type.newtype(:dockerimage) do
  desc 'Local docker image'

  ensurable do
    desc "Create or remove the image."
    newvalue(:present) do
      provider.pull
    end
    newvalue(:absent) do
      provider.rmi
    end
    defaultto :present
  end

 

end
