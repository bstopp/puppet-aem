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

  aem_wcmcommand { "wcmcmd-${name}" :
    ensure          => $ensure,
    home            => $home,
    username        => $username,
    password        => $password,
    configuration   => {
      'cmd'         => 'createPage',
      '_charset_'   => 'utf-8',
      ':status'     => 'browser',
      'parentPath'  => "/etc/replication/agents.${on}",
      'title'       => $description,
      'label'       => $name,
      'template'    => '/libs/cq/replication/templates/agent'
    }
  }

  # TODO, something like this:
  #aem_configure_page { "page-${name}" :
  #  home            => $home,
  #  username        => $username,
  #  password        => $password,
  #  configuration   => {}
  #}
}
