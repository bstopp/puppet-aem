# Default Publish Replication Agent Example

aem::agent::replication::publish { 'Publish Agent' :
  home           => '/opt/aem',
  name           => 'publish',
  password       => 'admin',
  runmode        => 'author',
  trans_password => 'admin',
  trans_uri      => 'http://localhost:4503/bin/receive?authRequestLogin=1',
  trans_user     => 'admin',
  username       => 'admin',
}