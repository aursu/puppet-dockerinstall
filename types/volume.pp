type Dockerinstall::Volume = Variant[
  String,
  Hash[String, Struct[{
        Optional[name]        => String,
        Optional[driver]      => String,
        Optional[driver_opts] => Hash[String, String],
        Optional[external]    => Boolean,
        Optional[labels]      => Variant[Array[String], Hash[String, String]],
  }]],
]
