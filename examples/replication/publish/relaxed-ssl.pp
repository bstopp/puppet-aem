# Relaxed SSL Update Publish Replication Agent Example

# Allow the remote system to use "invalid" or self-signed certs.

aem::agent::replication::publish { 'Publish Agent' :
  home                 => '/opt/aem',
  name                 => 'publish',
  password             => 'admin',
  runmode              => 'author',
  trans_allow_exp_cert => true,
  trans_password       => 'admin',
  trans_ssl            => 'relaxed',
  trans_uri            => 'http://localhost:4503/bin/receive?authRequestLogin=1',
  trans_user           => 'admin',
  username             => 'admin',
}