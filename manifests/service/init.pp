# == Define: aem::service::systemd
#
# Manages service defintion systems which employ systemd.
#
# This defines is not intended to be used directly.
#
# Based on Elastic Search service management.
#
define aem::service::init (
  $ensure,
  $status,
  $group,
  $home,
  $user,
) {
  # Setup the system state.
  if $ensure == 'present' {

    case $status {

      # Running now and on boot.
      'enabled': {
        $service_ensure   = 'running'
        $service_enabled  = true
      }
      # Not running now, nor on boot
      'disabled': {
        $service_ensure   = 'stopped'
        $service_enabled  = false
      }
      # Running now, but not on boot.
      'running': {
        $service_ensure   = 'running'
        $service_enabled  = false
      }
      # Basically, remove the service definition from catalog
      'unmanaged': {
        $service_ensure   = undef
        $service_enabled  = false
      }
      default: {
        fail("'${status}' is not a valid service status value")
      }
    }
  } else {
    # Shut it all down if 'absent'
    $service_ensure   = 'stopped'
    $service_enabled  = false
  }

  if ($status != 'unmanaged') {

    file { "/etc/init.d/aem-${name}":
      ensure  => $ensure,
      content => template("${module_name}/etc/init.d/init.erb"),
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
    }

    service { "aem-${name}":
      ensure     => $service_ensure,
      enable     => $service_enabled,
      name       => "aem-${name}",
      hasstatus  => true,
      hasrestart => true,
    }

    if ($ensure == 'present') {
      File["/etc/init.d/aem-${name}"]
      -> Service["aem-${name}"]

      File["/etc/init.d/aem-${name}"]
      ~> Service["aem-${name}"]

    } else {

      Service["aem-${name}"]
      -> File["/etc/init.d/aem-${name}"]

      Service["aem-${name}"]
      ~> File["/etc/init.d/aem-${name}"]
    }

  }
}