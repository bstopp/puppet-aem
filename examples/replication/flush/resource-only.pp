# Resource Only Flush Replication Agent Example

# This example creates a Flush replication agent, which will not trigger auto-invalidate rules.

aem::agent::replication::flush { 'Flush Agent' :
  home                  => '/opt/aem',
  name                  => 'flush',
  password              => 'admin',
  runmode               => 'author',
  protocol_http_headers => [ 'CQ-Action:{action}', 'CQ-Handle:{path}', 'CQ-Path: {path}', 'CQ-Action-Scope: ResourceOnly' ],
  trans_password        => 'admin',
  trans_uri             => 'http://localhost:80/dispatcher/invalidate.cache',
  trans_user            => 'admin',
  username              => 'admin',
}
