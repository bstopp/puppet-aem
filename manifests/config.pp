# == Define: aem::config
#
# Configure the AEM instance with the appropriate parameter values
#
# Do not use this defines directly.
#
define aem::config(
  $context_root,
  $debug_port,
  $group,
  $home,
  $jvm_mem_opts,
  $jvm_opts,
  $osgi_configs,
  $crx_packages,
  $port,
  $runmodes,
  $sample_content,
  $type,
  $user
) {

  File {
    group => $group,
    owner => $user,
  }


  # Create the env script
  file { "${home}/crx-quickstart/bin/start-env":
    ensure  => file,
    content => template("${module_name}/start-env.erb"),
    mode    => '0775',
  }

  # Rename the original start script.
  file { "${home}/crx-quickstart/bin/start.orig":
    ensure  => file,
    replace => false,
    source  => "${home}/crx-quickstart/bin/start",
    mode    => '0775',
  }

  # Create the start script
  file { "${home}/crx-quickstart/bin/start":
    ensure  => file,
    content => template("${module_name}/start.erb"),
    mode    => '0775',
    require => File["${home}/crx-quickstart/bin/start.orig"],
  }

  # Create the install folder in case there are any OSGi configurations; now or in the future
  file {"${home}/crx-quickstart/install" :
    ensure => directory,
    mode   => '0775',
  }

  if $osgi_configs {

    if is_array($osgi_configs) {
      $_osgi_configs = $osgi_configs
    } else {
      $_osgi_configs = [$osgi_configs]
    }

    $_osgi_configs.each | Hash $cfg | {

      $cfg.each | $key, $values | {

        if $values['properties'] {
          $_props = $values['properties']
          $_pid = $values['pid']
        } else {
          $_props = $values
          $_pid = undef
        }

        aem::osgi::config { $key :
          group      => $group,
          home       => $home,
          pid        => $_pid,
          properties => $_props,
          type       => 'file',
          user       => $user
        }
      }
    }
  }

  if $crx_packages {
    $crx_packages.each | $pkg | {
      $_filename = basename($pkg)
      aem::crx::package { "${home}/crx-quickstart/install/${_filename}" :
        group  => $group,
        home   => $home,
        source => $pkg,
        type   => 'file',
        user   => $user
      }
    }
  }
}
