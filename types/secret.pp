type Dockerinstall::Secret = Struct[{
    name                 => String,
    type                 => Enum['file', 'environment'],
    value                => String,
    Optional[setup]      => Boolean,
    Optional[filename]   => String,
}]
