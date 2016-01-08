
Puppet::Type.newtype(:aem_osgi_config) do

  @doc = <<-DOC
This is a private type used to manage OSGi co=nfigurations via API calls.
  DOC

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the OSGi configuration. This should be the SID.'
  end

  newproperty(:configuration) do
    desc 'Properties for the OSGi configuration.'

    validate do |value|
      unless value.is_a?(Hash)
        fail(Puppet::ResourceError, 'Config properties must be a hash of values.')
      end
    end

    def insync?(is)
      if resource[:handle_missing] == :merge
        should.each do |k, v|
          if !is.key?(k)
            # Desired state has a configuration value that doesn't exist
            return false
          elsif is[k] != v
            # Desired state's value is different than current state
            return false
          end
        end
        return true
      end

      # Default
      is == should
    end
  end

  newparam(:handle_missing) do
    desc 'How to handle missing configurations which exist in AEM.'
    newvalues(:merge, :remove)
  end

  newparam(:home) do
    desc 'The home directory of the AEM installation.'
    validate do |value|
      unless Puppet::Util.absolute_path?(value)
        fail(Puppet::ResourceError, "AEM Home must be fully qualified, not '#{value}'")
      end
    end
  end

  newparam(:username) do
    desc 'Username used to log into AEM.'
  end

  newparam(:password) do
    desc 'Password used to log into AEM.'
  end

  newparam(:timeout) do
    desc 'Timeout for a successful AEM start. Default = 60 seconds'

    newvalues(/^\d+$/)

    defaultto 60

    munge do |value|
      value.to_i
    end
  end

  validate do
    fail('AEM Home must be specified.') if self[:home].nil? || !self[:home]
  end
end
