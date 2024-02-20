type Dockerinstall::Version = Variant[
  Enum['present', 'installed', 'absent'],
  # https://docs.docker.com/engine/release-notes/
  Pattern[
    /^17\.12\./,
    /^17\.0[369]\./,
    /^18\.0[369]\./,
    /^(3:)?19\.03\./,
    /^([35]:)?20\.10\./,
    /^([135]:)?2[3-5]\.0\./,
  ],
]
