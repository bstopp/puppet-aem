require 'pathname'

Puppet::Type.newtype(:aem_installer) do

  @doc = <<-DOC
This is a private type intended to start, monitor, and stop an AEM instance, insuring
 the repository is created.
  DOC

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the AEM Instance.'

    munge do |value|
      value.downcase
    end

    def insync?(is)
      is.casecmp(should) == 0
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
        raise(Puppet::ResourceError, "AEM Home must be fully qualified, not '#{value}'")
      end

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
    raise(Puppet::ResourceError, 'AEM Home must be specified.') if self[:home].nil? || !self[:home]
  end
end
