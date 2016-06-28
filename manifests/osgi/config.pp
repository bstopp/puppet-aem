# == Define: aem::osgi::config
#
# Configure osgi resource based on the specified type.
#
define aem::osgi::config(
  $ensure         = 'present',
  $group          = 'aem',
  $handle_missing = undef,
  $home           = undef,
  $password       = undef,
  $pid            = undef,
  $properties     = undef,
  $type           = undef,
  $user           = 'aem',
  $username       = undef,
){

  validate_re($ensure, '^(present|absent)$',
    "${ensure} is not supported for ensure. Allowed values are 'present' and 'absent'.")

  validate_absolute_path($home)

  if $properties == undef {
    fail('Properties must contain at least one entry.')
  }

  if !is_hash($properties) {
    fail("Aem::Osgi::Config[${name}]: 'properties' must be a Hash of values")
  }

  validate_re($type, '^(console|file)$',
    "${type} is not supported for type. Allowed values are 'console' and 'file'.")

  if $type == 'console' {

    if $username == undef {
      fail("Username must be specified if type == 'console'")
    }
    if $password == undef {
      fail("Password must be specified if type == 'console'")
    }
    if $ensure == 'present' {
      validate_re($handle_missing, '^(merge|remove)$',
        "${handle_missing} is not supported for handle_missing. Allowed values are 'merge' and 'remove'.")
    }
  }

  case $type {
    'console' : {
      aem_osgi_config { $name :
        ensure         => $ensure,
        configuration  => $properties,
        handle_missing => $handle_missing,
        home           => $home,
        pid            => $pid,
        password       => $password,
        username       => $username,
      }
    }
    'file' : {
      aem::osgi::config::file { $name :
        ensure     => $ensure,
        group      => $group,
        home       => $home,
        pid        => $pid,
        properties => $properties,
        user       => $user,
      }
    }
    default : {
      fail("${type} is not supported for type. Allowed values are 'console' and 'file'.")
    }
  }
}
