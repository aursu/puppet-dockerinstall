type Dockerinstall::Version = Variant[
  Enum['present', 'installed', 'absent'],
  # https://docs.docker.com/engine/release-notes/
  Pattern[
    /^([135]:)?2[3-7]\.[0-4]\./,
  ],
]
