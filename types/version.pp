type Docker::Version = Variant[
    Enum['present', 'installed', 'absent'],
    Pattern[/^17\.1[0-2]\./, /^17\.0[3-9]\./, /^18\.01\./],  # https://docs.docker.com/release-notes/docker-ce/
    Pattern[/^1\.12\.6/, /^1\.13\.[01]/]                     # https://docs.docker.com/release-notes/docker-engine/
]