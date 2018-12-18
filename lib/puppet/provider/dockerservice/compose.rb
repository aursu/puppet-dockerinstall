Puppet::Type.type(:dockerservice).provide(
  :compose,
  # set ini_setting as the parent provider
  :parent => Puppet::Type.type(:service).provider(:base), # rubocop:disable Style/HashSyntax
) do
  @doc = 'Docker service provider'

  def self.basedir
    if File.directory?('/run')
      '/run/compose'
    else
      '/var/run/compose'
    end
  end

  commands compose: 'docker-compose'

  if command('compose')
    confine true: begin
                    compose('--version')
                  rescue Puppet::ExecutionFailure
                    false
                  else
                    true
                  end
  end
end
