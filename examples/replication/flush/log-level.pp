# Log Level Flush Replication Agent Example

# Change the log level setting of the replication agent.

aem::agent::replication::flush { 'Flush Agent' :
  home           => '/opt/aem',
  log_level      => 'error',
  name           => 'flush',
  password       => 'admin',
  runmode        => 'author',
  trans_password => 'admin',
  trans_uri      => 'http://localhost:80/dispatcher/invalidate.cache',
  trans_user     => 'admin',
  username       => 'admin',
}