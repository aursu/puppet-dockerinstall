type Dockerinstall::Numerical  = Variant[
    Integer,
    Pattern[/^[0-9]+$/, /^-[0-9]+$/]
]
