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
    mode    => '0755',
  }

  # Rename the original start script.
  file { "${home}/crx-quickstart/bin/start.orig":
    ensure  => file,
    replace => false,
    source  => "${home}/crx-quickstart/bin/start",
  }

  # Create the start script
  file { "${home}/crx-quickstart/bin/start":
    ensure  => file,
    content => template("${module_name}/start.erb"),
    mode    => '0755',
    require => File["${home}/crx-quickstart/bin/start.orig"],
  }

}
