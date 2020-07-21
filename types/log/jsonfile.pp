# https://docs.docker.com/config/containers/logging/json-file/
type Dockerinstall::Log::JSONFile = Struct[{
  Optional['max-size'] => Variant[Pattern[/^[0-9]+[gmk]?$/], Enum['-1']],
  Optional['max-file'] => Variant[Pattern[/^[0-9]+$/]],
  Optional['labels'] => String,
  Optional['env'] => String,
  Optional['env-regex'] => String,
  Optional['compress'] => Enum['true', 'false'],
  Optional['mode'] => Enum['blocking', 'non-blocking'],
  Optional['max-buffer-size'] => Pattern[/^[0-9]+[gmk]?$/],
}]
