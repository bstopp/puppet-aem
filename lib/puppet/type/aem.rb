require 'pathname'
require 'puppet/parameter/boolean'

Puppet::Type.newtype(:aem) do

  @doc = "Install AEM on a system. This includes:

      - Configuring pre-install properties for appropriate launch state.
      - Managing licensing information
      - Cycling the system after installation to ensure final state.

      A number of options are specified as properties, though they can
      not be changed after initial setup. They are specified as properties
      as they can be inspected, even if updating the value is not supported."

  ensurable
  # TODO: Consider adding other ensurable "managed" vs "unmanaged"

  # TODO: Consider adding features (crx2, mongo)

  newparam(:name, :namevar => true) do
    desc 'The name of the AEM Instance.'

    munge do |value|
      value.downcase
    end

    def insync?(is)
      is.downcase == should.downcase
    end
  end

  newparam(:source) do
    desc 'The AEM installer jar to use for installation.'

    validate do |value|
      fail("AEM installer jar (#{value}) not found.") unless File.file?(value)
    end

  end

  newparam(:timeout) do
    desc 'Timeout for the start process when monitoring for start and stop.
          If the system does not enter the necessary state by the timeout, an error is raised.

          Value is in seconds. Default = 10 minutes'

    defaultto 600
  end

  newparam(:snooze) do
    desc 'Snooze value for wait when monitoring for AEM state transition during installation.

          Value is in seconds; default = 10 seconds'

    defaultto 10
  end

  newproperty(:version) do
    desc 'The version of AEM installed.'

    newvalues(/^\d+\.\d+(\.\d+)?$/)

    munge do |value|
      "#{value}"
    end

    def insync?(is)
      warning("Version cannot be modified after installation. [Existing = #{is}, New = #{should}]") unless is == should
      true
    end

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
    desc 'The port on which AEM will listen.'

    defaultto 4502
    newvalues(/^\d+$/)
  end

  newproperty(:type) do
    desc 'The AEM type, either Author or Publish. See AEM documentation for more information.'

    defaultto :author
    newvalues(:author, :publish)
    def insync?(is)
      warning("Type cannot be modified after installation. [Existing = #{is}, New = #{should}]") unless is == should
      true
    end
  end

  newproperty(:runmodes, :array_matching => :all) do
    desc 'Runmodes for the Sling engine, excluding :type and :samplecontent'

    def insync?(is)
      if is.is_a?(Array) && @should.is_a?(Array)
        is.sort == @should.sort
      else
        is == @should
      end
    end
  end

  newproperty(:jvm_mem_opts) do
    desc 'The JVM Memory settings.'

    defaultto '-Xmx1024m -XX:MaxPermSize=256M'
  end

  newproperty(:context_root) do
    desc 'The context root.'
  end

  newproperty(:user) do
    def insync?(is)
      warning("User cannot be modified after installation. [Existing = #{is}, New = #{should}]") unless is == should
      true
    end
  end

  newproperty(:group) do
    def insync?(is)
      warning("Group cannot be modified after installation. [Existing = #{is}, New = #{should}]") unless is == should
      true
    end
  end

  newproperty(:sample_content, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Whether or not to include the sample content when starting the system.'

    defaultto true
    newvalues(true, false)
  end

  autorequire(:file) do
    autos = []

    autos << self[:source] if self[:source] && absolute_path?(self[:source])
    autos << self[:home] if self[:home] && absolute_path?(self[:home])

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
    if self[:ensure] == :present && self[:source].nil?
      fail('Source jar is required when ensure is present')
    end
  end

end
