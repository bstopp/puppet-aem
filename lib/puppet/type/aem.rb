
Puppet::Type.newtype(:aem) do

  @doc = "Install AEM on a system. This includes:

      - Configuring preinstall properties for appropriate launch state.
      - Manging licensing information
      - Cycling the system after installation to ensure final state."

  ensurable do
    newvalue(:present) do
      provider.install
    end
    
    newvalue(:absent) do
      provider.uninstall
    end
    
    newvalue(:purged)  do
      provider.purge
    end
    
  end
  
  newproperty(:home) do
    desc "The home directory of the AEM installation (defaults to '/opt/aem')"

#    validate do |value|
#      provider.validate_home(value)
#    end
#
#    defaultto '/opt/aem'
  end
  
#  newparam(:include_sample_content) do
#    desc "Specify whether or not to include sample content"
#    defaultto :true
#    newvalues(:true, :false)
#  end

#  newproperty(:port) do
#    desc "The port to which AEM will bind."
#    defaultto '4502'
#    newvalues(/^\d+$/)
#  end
  
  # TODO Add log level property 
  # TODO Add JVM property
  # TODO Add Mono properties
  # TODO Add Debug Properties
end