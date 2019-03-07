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
