type Dockerinstall::Version = Variant[
  Enum['present', 'installed', 'absent'],
  # https://docs.docker.com/engine/release-notes/
  Pattern[
    /^17\.1[0-2]\./,
    /^17\.0[3-9]\./,
    /^18\.0[1-9]\./,
    /^(3:)?19\.03\./,
    /^([35]:)?20\.10\./,
    /^(3:)?23\.0\./,
    /^([35]:)?24\.0\./,
  ],
]
