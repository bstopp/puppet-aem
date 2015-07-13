require 'pathname'

Puppet::Type.newtype(:aem) do

  @doc = "Install AEM on a system. This includes:

      - Configuring pre-install properties for appropriate launch state.
      - Managing licensing information
      - Cycling the system after installation to ensure final state."

  ensurable
  #TODO Consider adding other ensurable "managed" vs "unmanaged

  #TODO Consider adding features.

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

  newproperty(:version) do
    desc "The version of AEM installed."
    newvalues(/^\d+\.\d+(\.\d+)?$/)

    munge do |value|
      "#{value}"
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
    #TODO This can't be changed after installation

  end

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
        puts "Autorequire #{type}: #{val}"
        val
      end
    end
  end

  validate do
    if self[:ensure] == :present and self[:source].nil?
      fail('Source jar is required when ensure is present')
    end
    #if self[:ensure] == :present and self[:version].nil?
    #  fail('Version is required when ensure is present')
    #end
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