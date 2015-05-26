require 'puppet/provider/aem'


Puppet::Type.type(:aem).provide :linux, :parent => Puppet::Provider::AEM do
  desc "Parent AEM provider for Linux systems"

  def install
    Puppet.debug("Install called")
  end

end