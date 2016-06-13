# No Status Update Publish Replication Agent Example

# Disable the status updating when replicating.
aem::agent::replication::publish { 'Publish Agent' :
  home              => '/opt/aem',
  name              => 'publish',
  password          => 'admin',
  runmode           => 'author',
  trigger_no_status => true,
  trans_password    => 'admin',
  trans_uri         => 'http://localhost:4503/bin/receive?authRequestLogin=1',
  trans_user        => 'admin',
  username          => 'admin',
}
