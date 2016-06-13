# Transport User Publish Replication Agent Example

# This example creates a Publish replication agent, with a custom transport user credentials.

aem::agent::replication::publish { 'Publish Agent' :
  home            => '/opt/aem',
  name            => 'publish',
  password        => 'admin',
  runmode         => 'author',
  trans_password  => 'not-the-admin-password',
  trans_uri       => 'http://localhost:4503/bin/receive?authRequestLogin=1',
  trans_user      => 'not-the-admin-user',
  username        => 'admin',
}
