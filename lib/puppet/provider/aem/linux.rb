require 'puppet/provider/aem'

Puppet::Type.type(:aem).provide(:linux, :parent => Puppet::Provider::AEM) do

  mk_resource_methods

  def install
    Puppet.debug("Install called")
  end

end