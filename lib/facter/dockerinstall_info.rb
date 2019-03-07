require 'json'
Facter.add(:dockerinstall_info) do
  setcode do
    begin
      docker_info_json = `/usr/bin/docker info -f '{{json .}}'`
    rescue Errno::ENOENT
      docker_info_json = nil
    end
    if  $?.success?
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
