type Dockerinstall::Version = Variant[
    Enum['present', 'installed', 'absent'],
    # https://docs.docker.com/engine/release-notes/
    Pattern[
        /^17\.1[0-2]\./,
        /^17\.0[3-9]\./,
        /^18\.0[1-9]\./,
        /^(5:)?19\.03\./,
        /^(5:)?20\.10\./,
    ],
]
