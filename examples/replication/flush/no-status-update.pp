# No Status Update Flush Replication Agent Example

# This example disables not update the replication status of content when it is replicated.

aem::agent::replication::flush { 'Flush Agent' :
  home              => '/opt/aem',
  name              => 'flush',
  password          => 'admin',
  runmode           => 'author',
  trigger_no_status => true,
  trans_password    => 'admin',
  trans_uri         => 'http://localhost:80/dispatcher/invalidate.cache',
  trans_user        => 'admin',
  username          => 'admin',
}
