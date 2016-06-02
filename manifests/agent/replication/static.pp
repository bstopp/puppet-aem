# == Define: aem::agent::replication::flush
#
# Configure a Flush Replication Agent
define aem::agent::replication::static(
  $agent_user   = undef,
  $context_root = undef,
  $definition   = undef,
  $description  = undef,
  $directory    = undef,
  $enabled      = true,
  $ensure       = 'present',
  $home         = undef,
  $log_level    = undef,
  $password     = undef,
  $retry_delay  = undef,
  $runmode      = undef,
  $username     = undef
) {
  aem::agent::replication { $title :
    ensure            => $ensure,
    agent_user        => $agent_user,
    context_root      => $context_root,
    description       => $description,
    enabled           => $enabled,
    home              => $home,
    log_level         => $log_level,
    name              => $name,
    password          => $password,
    resource_type     => 'cq/replication/components/staticagent',
    retry_delay       => $retry_delay,
    runmode           => $runmode,
    serialize_type    => 'static',
    static_definition => $definition,
    static_directory  => $directory,
    template          => '/libs/cq/replication/templates/staticagent',
    username          => $username
  }
}
