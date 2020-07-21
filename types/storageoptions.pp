type Dockerinstall::StorageOptions = Variant[
  Pattern[/^dm\./],
  Pattern[/^zfs\.fsname=/],
  Pattern[/^btrfs\.min_space=/],
  Pattern[/^overlay2\.(override_kernel_check|size)=/],
]
