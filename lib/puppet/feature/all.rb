require 'puppet/util/feature'

Puppet.features.add(:aem_crx_pkg_client, libs: %w(crx_packmgr_api_client xml-simple))
