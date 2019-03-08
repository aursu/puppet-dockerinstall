require 'json'
Facter.add(:dockerinstall_info) do
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
        nil
      end
    else
      nil
    end
  end
end

Facter.add(:dockerinstall_swarm) do
  setcode do
    info = Facter.value(:dockerinstall_info)

    if info
      swarm = info['Swarm']

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
    else
      swarm = nil
    end
    swarm
  end
end
