require 'pathname'

Puppet::Type.newtype(:aem) do

  @doc = "Install AEM on a system. This includes:

      - Configuring pre-install properties for appropriate launch state.
      - Managing licensing information
      - Cycling the system after installation to ensure final state."

  ensurable
  #TODO Consider adding other ensurable "managed" vs "unmanaged"

  #TODO Consider adding features (crx2, mongo)

  newparam(:name, :namevar => true) do
    desc "The name of the AEM Instance."

    munge do |value|
      value.downcase
    end

    def insync?(is)
      is.downcase == should.downcase
    end
  end

  newparam(:source) do
    desc "The AEM installer jar to use for installation."

    validate do |value|
      fail("AEM installer jar (#{value}) not found.") unless File.file?(value)
    end

  end
  
  newparam(:timeout) do
    desc <<-EOT
      Timeout for the start process when monitoring for start and stop.
      If the system does not enter the necessary state by the timeout, an error is raised. 

      Value is in seconds. Default = 10 minutes
    EOT
    
    defaultto 6000
  end

  newparam(:snooze) do
    desc <<-EOT
      Snooze value for wait when monitoring for AEM state transition during installation.
      
      Value is in seconds; default = 10 seconds
    EOT
    
    defaultto 10
  end

  newproperty(:version) do
    desc "The version of AEM installed."

    newvalues(/^\d+\.\d+(\.\d+)?$/)

    munge do |value|
      "#{value}"
    end

    def insync?(is)
      is == should
    end

    #TODO This can't be changed after installation
  end

  newproperty(:home) do
    desc "The home directory of the AEM installation (defaults to 'C:/aem' or '/opt/aem')"

    defaultto do
      Puppet::Util::Platform.windows? ? 'C:/aem' : '/opt/aem'
    end

    validate do |value|
      unless Puppet::Util.absolute_path?(value)
        fail Puppet::ResourceError, "AEM Home must be fully qualified, not '#{value}'"
      end
      fail("AEM home directory (#{value}) not found.") unless File.directory?(value)

    end

  end

  newproperty(:port) do

    defaultto 4502
    newvalues(/^\d+$/)

  end

  newproperty(:type) do

    defaultto :author
    newvalues(:author, :publish)
    
    def issync?(is)
      warning( "Type cannot be modified after installation. [Existing = #{@property_hash[:type]}, New = #{value}]") unless is == should 
      true
    end
  end

  # TODO Add samplecontent property
  # TODO Add runmodes properties
  # TODO Add log level property
  # TODO Add JVM property
  # TODO Add Mongo properties
  # TODO Add Debug Properties

  newproperty(:user) do
    #TODO This can't be changed after installation
  end

  newproperty(:group) do
    #TODO This can't be changed after installation
  end

  autorequire(:file) do
    autos = []

    if source = self[:source] and absolute_path?(source)
      autos << source
    end
    if home = self[:home] and absolute_path?(home)
      autos << home
    end

    autos
  end

  autorequire(:user) do
    @parameters[:user]
  end

  [:user, :group].each do |type|
    autorequire(type) do
      if @parameters.include?(type)
        val = @parameters[type]
        val
      end
    end
  end

  validate do
    if self[:ensure] == :present and self[:source].nil?
      fail('Source jar is required when ensure is present')
    end
  end

end