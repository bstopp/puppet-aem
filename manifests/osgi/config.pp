# == Define: aem::osgi::config
#
# Configure osgi resource based on the specified type.
#
define aem::osgi::config(
  $ensure     = 'present',
  $group      = 'aem',
  $home       = undef,
  $properties = undef,
  $type       = undef,
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

  validate_re($type, '^(console|file)$', )

  case $type {
    'console' : {
      fail('Console option not supported yet.')
    }
    'file' : {
      aem::osgi::config::file { $name :
        ensure     => $ensure,
        group      => $group,
        home       => $home,
        properties => $properties,
        user       => $user,
      }
    }
    default : {
      fail("${type} is not supported for type. Allowed values are 'console' and 'file'.")
    }
  }
}
