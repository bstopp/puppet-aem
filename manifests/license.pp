
define aem::license (
  $ensure      = 'present',
  $customer    = undef,
  $group       = 'aem',
  $home        = undef,
  $license_key = undef,
  $user        = 'aem',
  $version     = undef) {

  validate_re($ensure, '^(present|absent)$', "${ensure} is not supported for ensure. Allowed values are 'present' and 'absent'.")

  if $home == undef {
    fail('Home directory must be specified.')
  }

  validate_absolute_path($home)

  if $license_key == undef {
    fail('License key must be specified.')
  }

  # Create the env script
  file { "${home}/license.properties":
    ensure  => $ensure,
    content => template("${module_name}/license.properties.erb"),
    group   => $group,
    mode    => '0644',
    owner   => $user,
  }

}
