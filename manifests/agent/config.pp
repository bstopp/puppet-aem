# == Define: aem::agent::config
#
# Configure a Replication Agent
define aem::agent::config(
  $ensure            = 'present',
  $status            = 'enabled',
  $description       = 'Replication Agent',
  $on                = 'author',
  $username          = 'admin',
  $password          = 'admin',
  $home              = undef,
  $charset           = 'utf-8',
  $loglevel          = 'info',
  $retrydelay        = '6000',
  $serializationtype = 'durbo',
  $template          = '/libs/cq/replication/templates/agent',
  $resourcetype      = 'cq/replication/components/agent',
  $transportpassword = 'password',
  $transporturi      = 'http://host:port/bin/receive?sling:authRequestLogin=1',
  $transportuser     = 'replication-receiver',
  $replicationuser   = 'your_replication_user',
  $handle_missing    = 'ignore',
) {
  validate_re($ensure, '^(present|absent)$', "${ensure} is not supported for ensure. Allowed values are 'present' and 'absent'.")

  if $name {
    validate_string($name)
  }

  validate_string($status)
  validate_string($description)
  validate_string($on)
  validate_string($username)
  validate_string($password)
  validate_absolute_path($home)
  validate_string($charset)
  validate_string($loglevel)
  validate_string($retrydelay)
  validate_string($serializationtype)
  validate_re($template, '^\/.*$', "${template} should be a absolute path starting with /.")
  validate_string($resourcetype)
  validate_string($transportpassword)
  validate_string($transporturi)
  validate_string($transportuser)
  validate_string($replicationuser)
  validate_string($handle_missing)
  validate_re($status, '^(enabled|disabled)$', "${status} is not supported for status. Allowed values are 'enabled' and 'disabled'.")
  validate_re($handle_missing, '^(remove|ignore)$', "${status} is not supported for handle_missing. Allowed values are 'remove' and 'ignore'.")

  case $status {
    'enabled': {
      $agent_enabled = true
    }
    'disabled': {
      $agent_enabled = false
    }
    default: {
      fail("'${status}' is not a valid agent status value")
    }
  }

  aem_sling_resource { $name :
    ensure         => $ensure,
    path           => "/etc/replication/agents.${on}/${name}",
    handle_missing => $handle_missing,
    home           => $home,
    username       => $username,
    password       => $password,
    properties     => {
      'jcr:primaryType' => 'cq:Page',
      'jcr:content'     => {
        'jcr:primaryType'    => 'nt:unstructured',
        'cq:template'        => $template,
        '_charset_'          => $charset,
        'enabled'            => $agent_enabled,
        'jcr:description'    => $description,
        'jcr:title'          => $description,
        'logLevel'           => $loglevel,
        'retryDelay'         => $retrydelay,
        'serializationType'  => $serializationtype,
        'sling:resourceType' => $resourcetype,
        'transportPassword'  => $transportpassword,
        'transportUri'       => $transporturi,
        'transportUser'      => $transportuser,
        'userId'             => $replicationuser,
      },
    },
  }
}
