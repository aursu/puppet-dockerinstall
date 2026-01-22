type Dockerinstall::Secret = Struct[{
    name                 => String,
    type                 => Enum['file', 'environment'],
    value                => String,
    Optional[setup]      => Boolean,
    Optional[filename]   => String,
    Optional[uid]        => Pattern[/^[1-9][0-9]*/],
    Optional[gid]        => Pattern[/^[1-9][0-9]*/]
}]
