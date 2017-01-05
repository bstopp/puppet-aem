# class: aem::params
#
# this class manages aem default parameters

class aem::params {

  $crx_packmgr_api_client_ver = '1.1.1'

  # Gem provider may vary based on version/type of puppet install.
  # This can be a little complicated and may need revisited over time.
  # Thanks to zabbix module.
  if str2bool($::is_pe) {
    if $::pe_version and versioncmp($::pe_version, '3.7.0') >= 0 {
      $puppetgem = 'pe_puppetserver_gem'
    } else {
      $puppetgem = 'pe_gem'
    }
  } else {
    $puppetgem = 'puppet_gem'
  }

  $xmlsimple_ver = '>=1.1.5'

}