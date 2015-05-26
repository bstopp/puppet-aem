#require 'puppet/provider/aem'


Puppet::Type.type(:aem).provide(:linux, :parent => Puppet::Provider::AEM) do

  #commands :java => 'java'

  def install
    Puppet.debug("Install called")
  end

end