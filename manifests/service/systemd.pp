# == Define: aem::service::systemd
#
# Manages service definition systems which employ systemd.
#
# This defines is not intended to be used directly.
#
# Based on Elastic Search service management.
#
define aem::service::systemd (
  $ensure,
  $status,
  $group,
  $home,
  $user,
  Hash $systemd_service_options = { 'PrivateTmp' => true },
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

    file { "/lib/systemd/system/aem-${name}.service":
      ensure  => $ensure,
      content => template("${module_name}/etc/init.d/systemd.erb"),
      owner   => 'root',
      group   => 'root',
    }

    service { "aem-${name}":
      ensure     => $service_ensure,
      enable     => $service_enabled,
      name       => "aem-${name}.service",
      hasstatus  => true,
      hasrestart => true,
      provider   => 'systemd',
    }

    if ($ensure == 'present') {
      File["/lib/systemd/system/aem-${name}.service"]
      -> Exec["reload_systemd_aem_${name}"]
      -> Service["aem-${name}"]

      File["/lib/systemd/system/aem-${name}.service"]
      ~> Exec["reload_systemd_aem_${name}"]
      ~> Service["aem-${name}"]
    } else {

      Service["aem-${name}"]
      -> File["/lib/systemd/system/aem-${name}.service"]

      Service["aem-${name}"]
      ~> File["/lib/systemd/system/aem-${name}.service"]
      ~> Exec["reload_systemd_aem_${name}"]
    }

  }

  exec { "reload_systemd_aem_${name}" :
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }
}
