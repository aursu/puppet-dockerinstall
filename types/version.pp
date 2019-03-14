type Dockerinstall::Version = Variant[
    Enum['present', 'installed', 'absent'],
    Pattern[/^17\.1[0-2]\./, /^17\.0[3-9]\./, /^18\.0[1-9]\./],  # https://docs.docker.com/engine/release-notes/
    Pattern[/^1\.12\.6/, /^1\.13\.[01]/]                         # https://docs.docker.com/release-notes/docker-engine/
]
