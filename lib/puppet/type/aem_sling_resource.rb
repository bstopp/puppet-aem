
Puppet::Type.newtype(:aem_sling_resource) do

  @doc = <<-DOC
This is a type used to perform sling api calls
  DOC

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The full path of the content node'
  end

  newparam(:handle_missing) do
    desc 'How to handle missing configurations which exist in AEM.'
    newvalues(:ignore, :remove)
    defaultto :ignore
  end

  newparam(:home) do
    desc 'The home directory of the AEM installation.'
    validate do |value|
      unless Puppet::Util.absolute_path?(value)
        raise(Puppet::ResourceError, "AEM Home must be fully qualified, not '#{value}'")
      end
    end
  end

  newparam(:username) do
    desc 'Username used to log into AEM.'
  end

  newparam(:path) do
    desc 'Path to the resource in the repository.'
  end

  newparam(:password) do
    desc 'Password used to log into AEM.'
  end

  newproperty(:properties) do
    desc 'Properties for the node.'

    validate do |value|
      unless value.is_a?(Hash)
        raise(Puppet::ResourceError, 'Properties must be a hash of values.')
      end
    end

    def insync?(is)

      depth_comp = lambda do |should_hsh, is_hsh|
        match = true
        should_hsh.each do |k, v|
          if v.is_a?(Hash) && is_hsh[k].is_a?(Hash)

            match = depth_comp.call(v, is_hsh[k])
            return match unless match
          else

            return false unless v == is_hsh[k]
          end
        end
        match
      end

      case resource[:handle_missing]
      when :ignore, :merge
        return depth_comp.call(resource[:properties], is)
      when :remove
        return is == should
      else
        raise(Puppet::ResourceError, "Invalid value for :handle_missing: #{resource[:handle_missing]}")
      end

    end
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
    raise(Puppet::ResourceError, 'AEM Home must be specified.') if self[:home].nil? || !self[:home]
  end
end
