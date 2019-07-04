# == Define: aem::crx::package
#
# Used to install a CRX Package.
#
define aem::crx::package (
  $ensure          = 'present',
  $group           = 'aem',
  $home            = undef,
  $manage_rubygems = true,
  $pkg_group       = undef,
  $pkg_name        = undef,
  $pkg_version     = undef,
  $password        = undef,
  $source          = undef,
  $timeout         = undef,
  $type            = undef,
  $user            = 'aem',
  $username        = undef,
  $retries         = undef,
  $retry_timeout   = undef,
) {

  validate_re($ensure, '^(present|installed|absent|purged)$',
    "${ensure} is not supported for ensure. Allowed values are: 'present', 'installed', 'absent' or 'purged'.")

  validate_absolute_path($home)

  if $ensure != 'absent' and $ensure != 'purged' {
    validate_absolute_path($source)
  }

  case $type {
    'api': {

      if $username == undef {
        fail("Username is required when type == 'api'")
      }
      if $password == undef {
        fail("Password is required when type == 'api'")
      }

      if $pkg_group == undef {
        fail("Package Group is required when type == 'api'")
      }

      if $pkg_name == undef {
        fail("Package Name is required when type == 'api'")
      }

      if $pkg_version == undef {
        fail("Package Version is required when type == 'api'")
      }

      if $manage_rubygems {
        include ::aem

        ensure_packages({
          'crx_packmgr_api_client' => {
            'ensure'   => $aem::crx_packmgr_api_client_ver,
            'provider' => $aem::puppetgem
          },
          'xml-simple' => {
            'ensure'   => $aem::xmlsimple_ver,
            'provider' => $aem::puppetgem
          }
        })

        Class['aem']
        -> Package['xml-simple']
        -> Package['crx_packmgr_api_client']
        -> Aem_Crx_Package[$title]
      }

      aem_crx_package { $title :
        ensure        => $ensure,
        group         => $pkg_group,
        home          => $home,
        password      => $password,
        pkg           => $pkg_name,
        source        => $source,
        username      => $username,
        version       => $pkg_version,
        timeout       => $timeout,
        retries       => $retries,
        retry_timeout => $retry_timeout
      }
    }
    'file': {

      case $ensure {
        /^(present|installed)$/ : { $_ensure = 'present' }
        'absent': { $_ensure = $ensure }
        'purged': { $_ensure = 'absent' }
        default: { $_ensure = 'pesent' }
      }
      aem::crx::package::file { $title :
        ensure => $_ensure,
        group  => $group,
        home   => $home,
        name   => $name,
        source => $source,
        user   => $user,
      }
    }
    default: {
      fail("${type} is not supported for type. Allowed values are 'api' and 'file'.")
    }
  }
}
