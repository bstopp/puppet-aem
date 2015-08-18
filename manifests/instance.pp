
define aem::instance (
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
  $type           = author,
  $user           = 'aem',
  $version        = undef) {
  anchor { 'aem::begin': }

  validate_re($ensure, '^(present|absent)$', "${ensure} is not supported for ensure. Allowed values are 'present' and 'absent'.")

  if $debug_port {
    validate_integer($debug_port)
  }

  if !$home {
    case $::kernel {
      'Linux' : { $_home = '/opt/aem' }
      default : { fail("'${module_name}' has no default 'home' value for '${::kernel}'") }
    }
  } else {
    $_home = $home
  }

  validate_absolute_path($_home)

  validate_bool($manage_group)

  if $manage_group {
    group { $group: ensure => $ensure, }
  }

  validate_bool($manage_user)

  if $manage_user {
    user { $user:
      ensure => $ensure,
      gid    => $group,
    }
  }

  validate_bool($manage_home)

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

  # ### Manage actions

  # package(s)
  aem::package { $name :
    ensure      => $ensure,
    group       => $group,
    home        => $_home,
    manage_home => $manage_home,
    source      => $source,
    user        => $user,
  }

  # configuration
  aem::config { $name :
    context_root   => $context_root,
    debug_port     => $debug_port,
    group          => $group,
    home           => $_home,
    jvm_mem_opts   => $jvm_mem_opts,
    jvm_opts       => $jvm_opts,
    port           => $port,
    runmodes       => $runmodes,
    sample_content => $sample_content,
    type           => $type,
    user           => $user,
  }

  aem_installer { $name:
    ensure       => $ensure,
    context_root => $context_root,
    group        => $group,
    home         => $_home,
    port         => $port,
    snooze       => $snooze,
    timeout      => $timeout,
    user         => $user,
  }

  if ($ensure == 'present') {
    if $manage_group {
      Anchor['aem::begin']
      -> Group[$group]
      -> Aem::Package[$name]
    }

    if $manage_user {
      Anchor['aem::begin']
      -> User[$user]
      -> Aem::Package[$name]
    }

    Anchor['aem::begin']
    -> Aem::Package[$name]
    -> Aem::Config[$name]
    -> Aem_Installer[$name]

  } else {
    Anchor['aem::begin']
    -> Aem::Package[$name]

  }
}
