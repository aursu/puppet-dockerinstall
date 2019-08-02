require 'json'
Facter.add(:docker_info) do
  setcode do
    docker_info_json =  if File.executable?('/usr/bin/docker')
                          `/usr/bin/docker info -f '{{json .}}'`
                        else
                          nil
                        end
    if docker_info_json && $?.success?
      begin
        JSON.parse(docker_info_json)
      rescue JSON::ParserError
        {}
      end
    else
      {}
    end
  end
end

Facter.add(:docker_swarm) do
  setcode do
    info = Facter.value(:docker_info)

    if info.empty?
      {}
    else
      swarm = info['Swarm']

      # it could be nil on this point when Docker daemon is not running
      return {} if swarm.nil?

      if swarm['ControlAvailable']
        swarm_join_token_worker = `/usr/bin/docker swarm join-token -q worker`
        swarm_join_token_manager = `/usr/bin/docker swarm join-token -q manager`

        swarm['JoinTokens'] = {
          'Worker' => swarm_join_token_worker.strip,
          'Manager' => swarm_join_token_manager.strip
        }
      else
        swarm['JoinTokens'] = {}
      end

      swarm
    end
  end
end
