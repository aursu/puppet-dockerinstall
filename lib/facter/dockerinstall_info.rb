require 'json'
Facter.add(:dockerinstall_info) do
  setcode do
    if File.executable?('/usr/bin/docker')
      docker_info_json = `/usr/bin/docker info -f '{{json .}}'`
    else
      docker_info_json = nil
    end
    if docker_info_json && $?.success?
      begin
        dockerinstall_info = JSON.parse(docker_info_json)
      rescue JSON::ParserError
        dockerinstall_info = nil
      end
    else
      dockerinstall_info = nil
    end
    dockerinstall_info
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
