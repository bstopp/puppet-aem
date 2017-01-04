# This class exists soley to ensure that the module is properly defined.

class aem (
  $crx_packmgr_api_client_ver = $aem::params::crx_packmgr_api_client_ver,
  $puppetgem                  = $aem::params::puppetgem,
  $xmlsimple_ver              = $aem::params::xmlsimple_ver
) inherits aem::params {}
