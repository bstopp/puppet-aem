Puppet::Type.newtype(:aem_wcmcommand) do

  @doc = <<-DOC
This is a type used to perform wcmcommands
  DOC

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the resource'
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

  newproperty(:configuration) do
    desc 'Properties for the OSGi configuration.'

    validate do |value|
      unless value.is_a?(Hash)
        fail(Puppet::ResourceError, 'Config properties must be a hash of values.')
      end
    end
  end

  validate do
    fail('AEM Home must be specified.') if self[:home].nil? || !self[:home]
  end
end
