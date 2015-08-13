
class aem (
  $ensure         = 'present',
  $context_root   = undef,
  $debug_port     = undef,
  $group          = 'aem',
  $home           = undef,
  $jvm_mem_opts   = '-Xmx1024m -XX:MaxPermSize=256M',
  $jvm_opts       = undef,
  $manage_group   = true,
  $manage_home    = true,
  $manage_user    = true,
  $port           = 4502,
  $runmodes       = [],
  $sample_content = true,
  $snooze         = 10,
  $source         = undef,
  $timeout        = 600,
  $type           = 'author',
  $user           = 'aem',
  $version        = undef,) {
  validate_re($ensure, '^(present|absent)$', "${ensure} is not supported for ensure. Allowed values are 'present' and 'absent'.")

  if $debug_port {
    validate_integer($debug_port)
  }

  if $home == undef {
    $_home = '/opt/aem'
  } else {
    $_home = $home
  }

  validate_absolute_path($_home)

  validate_bool($manage_group)

  if $manage_group {
    group { $group: ensure => present, }
  }
  validate_bool($manage_user)

  if $manage_user {
    user { $user:
      ensure => present,
      gid    => $group,
    }
  }

  validate_bool($manage_home)

  if !defined(File[$_home]) and $manage_home {
    file { $_home:
      ensure => directory,
      group  => $group,
      owner  => $user,
    }
  }

  validate_integer($port)

  validate_array($runmodes)

  validate_bool($sample_content)
  validate_integer($snooze)
  validate_absolute_path($source)

  validate_integer($timeout)

  validate_re($type, '^(author|publish)$', "${type} is not supported for type. Allowed values are 'author' and 'publish'.")

  if $version {
    validate_re($version, '^\d+\.\d+(\.\d+)?$', "${version} is not a valid version.")
  }

  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
  }

  # Unpack the Jar
  exec { "${title} unpack":
    command => "java -jar ${source} -b ${_home} -unpack",
    creates => "${_home}/crx-quickstart",
    group   => $group,
    onlyif  => ['which java', "test -f ${source}"],
    user    => $user,
    require => File[$_home],
  }

  # Create the env script
  file { "${_home}/crx-quickstart/bin/start-env" :
    ensure  => file,
    content => template('aem/start-env.erb'),
    group   => $group,
    owner   => $user,
    require => Exec["${title} unpack"],
  }

  # Rename the original start script.
  file { "${_home}/crx-quickstart/bin/start.orig" :
    ensure  => file,
    group   => $group,
    source  => "${_home}/crx-quickstart/bin/start",
    owner   => $user,
    require => Exec["${title} unpack"],
  }

  # Create the start script
  file { "${_home}/crx-quickstart/bin/start" :
    ensure  => file,
    group   => $group,
    source  => 'puppet:///modules/aem/start',
    owner   => $user,
    require => File["${_home}/crx-quickstart/bin/start.orig"],
  }

  # Start the repository
  exec { "${title} start" :
    command => 'start',
    creates => "${_home}/crx-quickstart/repository",
    group   => $group,
    path    => "${_home}/crx-quickstart/bin",
    user    => $user,
    require => File["${_home}/crx-quickstart/bin/start"]
  }

  file { "${_home}/crx-quickstart/bin/monitor" :
    ensure  => file,
    content => template('aem/monitor.erb'),
    group   => $group,
    owner   => $user,
    require => Exec["${title} unpack"]
  }

  exec { "${title} stop" :
    command => 'stop',
    group   => $group,
    onlyif  => 'monitor on',
    path    => "${_home}/crx-quickstart/bin",
    user    => $user,
    require => Exec["${title} start"]
  }
}
