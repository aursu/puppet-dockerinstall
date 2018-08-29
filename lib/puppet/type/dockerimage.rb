Puppet::Type.newtype(:dockerimage) do
  @doc = "Local docker image"

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

  newparam(:tag) do
    desc "Tag is the mechanism that registries use to give Docker images a
    version"
  end

  newparam(:path) do
    desc "Path is username/repository part of image name"
  end

  newparam(:domain) do
    desc "Domain is registry host:port. port is optional"
  end

  newparam(:id) do
    desc "ID is image id"
  end

end
