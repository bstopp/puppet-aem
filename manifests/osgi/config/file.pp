# == Define: aem::osgi::config::file
#
# Creates an OSGI configuration file in the install folder..
#
define aem::osgi::config::file(
  $ensure     = 'present',
  $group      = 'aem',
  $home       = undef,
  $properties = undef,
  $user       = 'aem'
){

  validate_re($ensure, '^(present|absent)$', "${ensure} is not supported for ensure. Allowed values are 'present' and 'absent'.")

  validate_absolute_path($home)

  if $properties == undef {
    fail('Properties must contain at least one entry.')
  }

  if !is_hash($properties) {
    fail("Aem::Osgi::Config::File[${name}]: 'properties' must be a Hash of values")
  }

  $file_props = {
    'properties' => $properties
  }

  file { "${home}/crx-quickstart/install/${name}.config" :
    ensure  => $ensure,
    group   => $group,
    content => epp("${module_name}/osgi.config.epp", $file_props),
    mode    => '0664',
    owner   => $user,
  }

  if defined(File[$home]) {
    File[$home]
    -> File["${home}/crx-quickstart/install/${name}.config"]
  }
}
