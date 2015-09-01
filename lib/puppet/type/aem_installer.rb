require 'pathname'

Puppet::Type.newtype(:aem_installer) do

  @doc = <<-DOC
This is a private class intended to start, monitor, and stop an AEM instance, insuring
 the repository is created.
  DOC

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the AEM Instance.'

    munge do |value|
      value.downcase
    end

    def insync?(is)
      is.downcase == should.downcase
    end
  end

  newparam(:context_root) do
    desc 'The context root.'
  end

  newproperty(:group) do
    def insync?(is)
      warning("Group cannot be modified after installation. [Existing = #{is}, New = #{should}]") unless is == should
      true
    end
  end

  newproperty(:home) do
    desc 'The home directory of the AEM installation.'
    def insync?(is)
      warning("Home cannot be modified after installation. [Existing = #{is}, New = #{should}]") unless is == should
      true
    end

    validate do |value|

      unless Puppet::Util.absolute_path?(value)
        fail Puppet::ResourceError, "AEM Home must be fully qualified, not '#{value}'"
      end

    end
  end

  newparam(:port) do
    desc 'The port on which AEM will listen.'

    newvalues(/^\d+$/)

    munge do |value|
      value.to_i
    end
  end

  newparam(:snooze) do
    desc 'Snooze value for wait when monitoring for AEM state transition during installation.
          Value is in seconds; default = 10 seconds'

    newvalues(/^\d+$/)
    
    munge do |value|
      value.to_i
    end
  end

  newparam(:timeout) do
    desc 'Timeout for the start process when monitoring for start and stop.
          If the system does not enter the necessary state by the timeout, an error is raised.
          Value is in seconds. Default = 10 minutes'

    newvalues(/^\d+$/)

    munge do |value|
      value.to_i
    end
  end

  newproperty(:user) do
    def insync?(is)
      warning("User cannot be modified after installation. [Existing = #{is}, New = #{should}]") unless is == should
      true
    end
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

  autorequire(:file) do
    autos = []
    autos << self[:home] if self[:home] && absolute_path?(self[:home])
    autos
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
    fail('AEM Home must be specified.') if self[:home].nil? || !self[:home]
  end
end
