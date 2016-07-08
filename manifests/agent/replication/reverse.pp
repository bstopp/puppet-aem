# == Define: aem::agent::replication::reverse
#
# Configure a Reverse Replication Agent
define aem::agent::replication::reverse(
  $agent_user           = undef,
  $description          = undef,
  $enabled              = true,
  $ensure               = 'present',
  $force_passwords      = undef,
  $home                 = undef,
  $log_level            = undef,
  $password             = undef,
  $protocol_http_method = 'GET',
  $runmode              = undef,
  $timeout              = undef,
  $trans_allow_exp_cert = undef,
  $trans_password       = undef,
  $trans_ssl            = undef,
  $trans_uri            = undef,
  $trans_user           = undef,
  $username             = undef
) {
  aem::agent::replication { $title :
    ensure               => $ensure,
    agent_user           => $agent_user,
    description          => $description,
    enabled              => $enabled,
    force_passwords      => $force_passwords,
    home                 => $home,
    log_level            => $log_level,
    name                 => $name,
    password             => $password,
    protocol_http_method => $protocol_http_method,
    resource_type        => 'cq/replication/components/revagent',
    reverse              => true,
    runmode              => $runmode,
    serialize_type       => 'durbo',
    template             => '/libs/cq/replication/templates/revagent',
    timeout              => $timeout,
    trans_allow_exp_cert => $trans_allow_exp_cert,
    trans_password       => $trans_password,
    trans_ssl            => $trans_ssl,
    trans_uri            => $trans_uri,
    trans_user           => $trans_user,
    username             => $username
  }
}
