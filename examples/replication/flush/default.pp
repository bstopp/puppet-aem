# Default Flush Replication Agent Example

aem::agent::replication::publish { 'Flush Agent' :
  home            => '/opt/aem',
  name            => 'flush',
  password        => 'admin',
  runmode         => 'author',
  trans_password  => 'admin',
  trans_uri       => 'http://localhost:80/dispatcher/invalidate.cache',
  trans_user      => 'admin',
  username        => 'admin',
}