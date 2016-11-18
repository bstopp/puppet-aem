# == Define: aem::package
#
# Used to unpack the AEM instance prior to configuration.
#
# Do not use this defines directly.
#
define aem::package (
  $ensure,
  $group,
  $home,
  $manage_home,
  $source,
  $user,
  $type = 'jar',
) {
  File {
    group => $group,
    owner => $user,
  }

  Exec {
    group => $group,
    path  => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
    user  => $user,
  }

  if $ensure == 'present' {
    # Manage home directory.
    if !defined(File[$home]) and $manage_home {
      file { $home:
        ensure => directory,
        mode   => '0775',
      }
    }

    if $type == 'jar' {
      if defined(File[$home]) {
        File[$home]
        -> Exec["${name} unpack"]
      }

      # Unpack the Jar
      exec { "${name} unpack":
        command => "java -jar ${source} -b ${home} -unpack",
        creates => "${home}/crx-quickstart",
        onlyif  => ['which java', "test -f ${source}"],
      }
    } elsif $type == 'os' {
      package { 'aem':
        ensure => installed,
      }
    } else {
      fail("Unsupported package type : ${type} !")
    }

  } else {
    # Remove installation
    file { "${home}/crx-quickstart": ensure => absent, force => true }

    # Remove managed home directory
    if !defined(File[$home]) and $manage_home {
      file { $home:
        ensure => absent,
        force  => true,
      }
    }

    if defined(File[$home]) {
      File["${home}/crx-quickstart"]
      -> File[$home]
    }
  }
}
