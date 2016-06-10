
# Dispatcher Class Examples

# Create with default values

class { 'aem::dispatcher' :
  module_file => '/path/to/dispatcher-module.so',
}


# Custom configuration values:

class { 'aem::dispatcher' :
  decline_root      => 1,
  dispatcher_name   => 'named-instance',
  log_file          => '/path/to/log/dir/my-dispatcher.log',
  log_level         => 3,
  module_file       => '/path/to/dispatcher-module.so',
  no_server_header  => 'on',
  use_processed_url => 1,
  pass_error        => '400-404,500',
}
