# Log Level Publish Replication Agent Example

# Change the log level setting of the replication agent.

aem::agent::replication::publish { 'Publish Agent' :
  home           => '/opt/aem',
  log_level      => 'error',
  name           => 'publish',
  password       => 'admin',
  runmode        => 'author',
  trans_password => 'admin',
  trans_uri      => 'http://localhost:4503/bin/receive?authRequestLogin=1',
  trans_user     => 'admin',
  username       => 'admin',
}