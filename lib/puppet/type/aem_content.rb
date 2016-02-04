Puppet::Type.newtype(:aem_content) do

  @doc = <<-DOC
This is a type used to perform sling api calls
  DOC

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The full path of the content node'
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

  newproperty(:properties) do
    desc 'Properties for the node.'

    validate do |value|
      unless value.is_a?(Hash)
        fail(Puppet::ResourceError, 'Properties must be a hash of values.')
      end
    end
  end

  validate do
    fail('AEM Home must be specified.') if self[:home].nil? || !self[:home]
  end
end
