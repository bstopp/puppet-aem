# Transport User Flush Replication Agent Example

# This example creates a Flush replication agent, with a custom transport user credentials.

aem::agent::replication::flush { 'Flush Agent' :
  home            => '/opt/aem',
  name            => 'flush',
  password        => 'admin',
  runmode         => 'author',
  trans_password  => 'not-the-admin-password',
  trans_uri       => 'http://localhost:80/dispatcher/invalidate.cache',
  trans_user      => 'not-the-admin-user',
  username        => 'admin',
}
}
