# Enabled on Publish Flush Replication Agent Example

# This example enables the Flush agent on the publish server, not the author.

aem::agent::replication::flush { 'Flush Agent' :
  home            => '/opt/aem',
  name            => 'flush',
  password        => 'admin',
  runmode         => 'publish',
  trans_password  => 'admin',
  trans_uri       => 'http://localhost:80/dispatcher/invalidate.cache',
  trans_user      => 'admin',
  username        => 'admin',
}

