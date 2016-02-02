# == Define: aem::agent::config
#
# Configure a Replication Agent
define aem::agent::config(
  $ensure       = 'present',
  $status       = 'enabled',
  $description  = 'Replication Agent',
  $on           = 'author',
  $username     = 'admin',
  $password     = 'admin',
  $home         = undef,
) {
  validate_re($ensure, '^(present|absent)$', "${ensure} is not supported for ensure. Allowed values are 'present' and 'absent'.")

  if $name {
    validate_string($name)
  }

  validate_absolute_path($home)

  if $ensure == 'present' {
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
  } else {
    $agent_enabled = false
  }

  aem_content { "/etc/replication/agents.author/${name}" :
    ensure     => $ensure,
    home       => $home,
    username   => $username,
    password   => $password,
    properties => {
      'jcr:primaryType' => 'cq:Page',
    },
    before => Aem_content["/etc/replication/agents.author/${name}/jcr:content"],
  }

  aem_content { "/etc/replication/agents.author/${name}/jcr:content" :
    ensure     => $ensure,
    home       => $home,
    username   => $username,
    password   => $password,
    properties => {
      'cq:template'        => '/libs/cq/replication/templates/agent',
      '_charset_'          => 'utf-8',
      ':status'            => 'browser',
      'enabled'            => $status,
      'jcr:description'    => $description,
      'jcr:title'          => $description,
      'logLevel'           => 'info',
      'retryDelay'         => '6000',
      'serializationType'  => 'durbo',
      'sling:resourceType' => 'cq/replication/components/agent',
      'transportPassword'  => 'password',
      'transportUri'       => 'http://host:port/bin/receive?sling:authRequestLogin=1',
      'transportUser'      => 'replication-receiver',
      'userId'             => 'your_replication_user',
    },
  }
}
