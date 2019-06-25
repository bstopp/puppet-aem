# frozen_string_literal: true

require 'puppet/parameter/boolean'

Puppet::Type.newtype(:aem_sling_resource) do

  @doc = <<-DOC
This is a type used to perform sling api calls
  DOC

  ensurable

  newparam(:name, namevar: true) do
    desc 'The full path of the content node, or a unique name for this resource.'
  end

  newparam(:force_passwords, boolean: true, parent: Puppet::Parameter::Boolean) do
    desc 'Force the updates of password properties if they differ.'
    defaultto false
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

  newparam(:ignored_properties, array_matching: :all) do
    desc 'The properties to ignore when checking for synchronization.'
    defaultto ['jcr:created', 'jcr:createdBy', 'cq:lastModified', 'cq:lastModifiedBy']
  end

  newparam(:path) do
    desc 'Path to the resource in the repository.'
  end

  newparam(:password) do
    desc 'Password used to log into AEM.'
  end

  newparam(:password_properties, array_matching: :all) do
    desc 'Properties designated as passwords, these will be ignored on sync check unless force_passwords is true.'
    defaultto []
  end

  newparam(:protected_properties, array_matching: :all) do
    desc 'Properties allowed when creating a node, but not during updates; ignored during synchronization.'
    defaultto ['jcr:primaryType']
  end

  newparam(:username) do
    desc 'Username used to log into AEM.'
  end

  newproperty(:properties) do
    desc 'Properties for the node.'

    validate do |value|
      raise(Puppet::ResourceError, 'Properties must be a hash of values.') unless value.is_a?(Hash)
    end

    def check_hash(hsh, key)
      hsh.include?(key.to_sym) || hsh.include?(key.to_s)
    end

    def ignore_comp(should_hsh, is_hsh)
      match = true
      should_hsh.each do |k, v|

        if v.is_a?(Hash) && is_hsh[k].is_a?(Hash)

          match = ignore_comp(v, is_hsh[k])
          return match unless match
        else
          next if check_hash(resource[:ignored_properties], k) ||
                  check_hash(resource[:protected_properties], k) ||
                  (!resource.force_passwords? &&
                    check_hash(resource[:password_properties], k))
          # Compare using Strings; response always have strings instead of boolean/number.
          return false unless v.to_s == is_hsh[k].to_s
        end
      end
      match
    end

    def remove_comp(should_hsh, is_hsh)

      should_keys = should_hsh.keys - resource[:ignored_properties] - resource[:protected_properties]
      is_keys = is_hsh.keys - resource[:ignored_properties] - resource[:protected_properties]

      unless resource.force_passwords?
        should_keys -= resource[:password_properties]
        is_keys -= resource[:password_properties]
      end
      return false unless should_keys.sort == is_keys.sort

      match = true
      should_keys.each do |k|
        if should_hsh[k].is_a?(Hash) && is_hsh[k].is_a?(Hash)
          match = remove_comp(should_hsh[k], is_hsh[k])
          return match unless match
        else
          # Compare using Strings; response always have strings instead of boolean/number.
          return false unless should_hsh[k].to_s == is_hsh[k].to_s
        end
      end
    end

    def insync?(is_val)

      case resource[:handle_missing]
      when :ignore
        ignore_comp(should, is_val)
      when :remove
        remove_comp(should, is_val)
      else
        raise(Puppet::ResourceError, "Invalid value for :handle_missing: #{resource[:handle_missing]}")
      end

    end
  end

  newparam(:retries) do
    desc 'Number of retries to communicate with AEM before giving up.'
    newvalues(/^\d+$/)

    defaultto 10

    munge(&:to_i)
  end

  newparam(:timeout) do
    desc 'Timeout for a successful AEM start. Default = 60 seconds'

    newvalues(/^\d+$/)

    defaultto 120

    munge do |value|
      value.to_i
    end
  end

  validate do
    raise(Puppet::ResourceError, 'AEM Home must be specified.') if self[:home].nil? || !self[:home]
  end
end
