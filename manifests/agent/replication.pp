# == Define: aem::agent::replication
#
# Configure a Replication Agent
define aem::agent::replication(

  $agent_user            = undef,
  $batch_enabled         = undef,
  $batch_max_wait        = undef,
  $batch_trigger_size    = undef,
  $context_root          = undef,
  $description           = undef,
  $enabled               = true,
  $ensure                = 'present',
  $home                  = undef,
  $log_level             = 'info',
  $password              = undef,
  $protocol_close_conn   = undef,
  $protocol_conn_timeout = undef,
  $protocol_http_headers = undef,
  $protocol_http_method  = undef,
  $protocol_interface    = undef,
  $protocol_sock_timeout = undef,
  $protocol_version      = undef,
  $proxy_host            = undef,
  $proxy_ntlm_domain     = undef,
  $proxy_ntlm_host       = undef,
  $proxy_password        = undef,
  $proxy_port            = undef,
  $proxy_user            = undef,
  $resource_type         = undef,
  $retry_delay           = undef,
  $reverse               = undef,
  $runmode               = undef,
  $serialize_type        = undef,
  $static_directory      = undef,
  $static_definition     = undef,
  $template              = undef,
  $timeout               = undef,
  $trans_allow_exp_cert  = undef,
  $trans_ntlm_domain     = undef,
  $trans_ntlm_host       = undef,
  $trans_password        = undef,
  $trans_ssl             = undef,
  $trans_uri             = undef,
  $trans_user            = undef,
  $trigger_ignore_def    = undef,
  $trigger_on_dist       = undef,
  $trigger_on_mod        = undef,
  $trigger_on_receive    = undef,
  $trigger_onoff_time    = undef,
  $trigger_no_status     = undef,
  $trigger_no_version    = undef,
  $username              = undef
) {

  validate_re($name, '^[A-Za-z0-9-]+$', "${name} must contain only letters and numbers.")

  validate_re($ensure, '^(present|absent)$', "${ensure} is not supported for ensure. Allowed values are 'present' and 'absent'.")

  validate_absolute_path($home)

  if $runmode == undef {
    fail("Parameter 'runmode' must be specified.")
  }

  if $password == undef {
    fail("Parameter 'password' must be specified.")
  }
  if $username == undef {
    fail("Parameter 'username' must be specified.")
  }

  if $ensure == 'present' {

    if $batch_enabled {
      validate_bool($batch_enabled)
    }
    if $batch_max_wait {
    validate_integer($batch_max_wait)
    }
    if $batch_trigger_size {
      validate_integer($batch_trigger_size)
    }

    validate_bool($enabled)

    validate_re($log_level, '^(debug|info|error)$',
      "${log_level} is not supported for log_level. Allowed values are 'debug', 'info', and 'error'.")

    if $protocol_close_conn {
      validate_bool($protocol_close_conn)
    }
    if $protocol_conn_timeout {
      validate_integer($protocol_conn_timeout)
    }
    if $protocol_http_headers {
      validate_array($protocol_http_headers)
    }
    if $protocol_sock_timeout {
      validate_integer($protocol_sock_timeout)
    }

    if $proxy_port {
      validate_integer($proxy_port)
    }

    if !$resource_type {
      fail("Parameter 'resource_type' must be specified.")
    }

    if $retry_delay {
      validate_integer($retry_delay)
    }

    if $reverse {
      validate_bool($reverse)
    }

    if !$template {
      fail("Parameter 'template' must be specified.")
    }

    if $timeout {
      validate_integer($timeout)
    }

    if $trans_allow_exp_cert {
      validate_bool($trans_allow_exp_cert)
    }

    if $trans_ssl {
      validate_re($trans_ssl, '^(default|relaxed|clientauth)$', "${trans_ssl} is not supported for trans_ssl. Allowed values are 'default', 'relaxed', and 'clientauth'.")
    }

    if $trigger_ignore_def {
      validate_bool($trigger_ignore_def)
    }
    if $trigger_no_status {
      validate_bool($trigger_no_status)
    }
    if $trigger_no_version {
      validate_bool($trigger_no_version)
    }
    if $trigger_on_dist {
      validate_bool($trigger_on_dist)
    }
    if $trigger_on_mod {
      validate_bool($trigger_on_mod)
    }
    if $trigger_on_receive {
      validate_bool($trigger_on_receive)
    }
    if $trigger_onoff_time {
      validate_bool($trigger_onoff_time)
    }

    if !$serialize_type {
      fail("Parameter 'serialize_type' must be specified.")
    }

    $_description = "**Managed by Puppet. Any changes made will be overwritten** ${description}"
  }

  $resource_props = {
    '_charset_'                   => 'utf-8',
    'jcr:primaryType'             => 'nt:unstructured',
    'userId'                      => $agent_user,
    'queueBatchMode'              => $batch_enabled,
    'queueBatchWaitTime'          => $batch_max_wait,
    'queueBatchMaxSize'           => $batch_trigger_size,
    'jcr:description'             => $_description,
    'enabled'                     => $enabled,
    'logLevel'                    => $log_level,
    'protocolHTTPConnectionClose' => $protocol_close_conn,
    'protocolConnectTimeout'      => $protocol_conn_timeout,
    'protocolHTTPMethod'          => $protocol_http_method,
    'protocolInterface'           => $protocol_interface,
    'protocolSocketTimeout'       => $protocol_sock_timeout,
    'protocolVersion'             => $protocol_version,
    'proxyHost'                   => $proxy_host,
    'proxyNTLMDomain'             => $proxy_ntlm_domain,
    'proxyNTLMHost'               => $proxy_ntlm_host,
    'proxyPassword'               => $proxy_password,
    'proxyPort'                   => $proxy_port,
    'proxyUser'                   => $proxy_user,
    'sling:resourceType'          => $resource_type,
    'retryDelay'                  => $retry_delay,
    'reverseReplication'          => $reverse,
    'serializationType'           => $serialize_type,
    'directory'                   => $static_directory,
    'definition'                  => $static_definition,
    'cq:template'                 => $template,
    'jcr:title'                   => $title,
    'protocolHTTPExpired'         => $trans_allow_exp_cert,
    'transportNTLMDomain'         => $trans_ntlm_domain,
    'transportNTLMHost'           => $trans_ntlm_host,
    'transportPassword'           => $trans_password,
    'ssl'                         => $trans_ssl,
    'transportUri'                => $trans_uri,
    'transportUser'               => $trans_user,
    'triggerSpecific'             => $trigger_ignore_def,
    'noStatusUpdate'              => $trigger_no_status,
    'noVersioning'                => $trigger_no_version,
    'triggerDistribute'           => $trigger_on_dist,
    'triggerModified'             => $trigger_on_mod,
    'triggerReceive'              => $trigger_on_receive,
    'triggerOnOffTime'            => $trigger_onoff_time
  }

  $_resource_props = delete_undef_values($resource_props)

  $path = "/etc/replication/agents.${runmode}/${name}"

  if $context_root {
    $_path = "/${context_root}${path}"
  } else {
    $_path = $path
  }

  aem_sling_resource { $title :
    ensure         => $ensure,
    handle_missing => remove,
    home           => $home,
    password       => $password,
    path           => $_path,
    properties     => {
      'jcr:primaryType' => 'cq:Page',
      'jcr:content'     => $_resource_props,
    },
    username       => $username,
  }

}
