# frozen_string_literal: true

Puppet::Type.newtype(:aem_crx_package) do

  @doc = <<-DOC
This is a private type used to manage CRX Packages via API calls.
  DOC

  ensurable do
    desc 'Upload, install/uninstall or remove the package.'

    newvalue(:present) do
      provider.upload
    end

    newvalue(:installed) do
      provider.install
    end

    newvalue(:absent) do
      provider.remove
    end

    newvalue(:purged) do
      provider.purge
    end

    def retrieve
      provider.retrieve
    end

    def insync?(is_val)
      retval = super(is_val)
      retval ||= (@should.include?(:absent) || @should.include?(:purged)) &&
                 (is_val.to_sym == :absent || is_val.to_sym == :purged)
      retval
    end
  end

  newparam(:name, namevar: true) do
    desc 'Namevar, Unique value to allow multiple resources in one manifest.'
  end

  newproperty(:pkg) do
    desc 'The name of the CRX package.'
    validate do |value|
      raise(Puppet::ResourceError, 'Package name must be specified.') if value.nil?
    end
  end

  newproperty(:group) do
    desc 'The group of the CRX Package.'
    validate do |value|
      raise(Puppet::ResourceError, 'Package group must be specified.') if value.nil?
    end
  end

  newproperty(:version) do
    desc 'The version of the CRX Package.'
    validate do |value|
      raise(Puppet::ResourceError, 'Package version must be specified.') if value.nil?
    end
  end

  newparam(:home) do
    desc 'The home directory of the AEM installation.'
    validate do |value|
      unless Puppet::Util.absolute_path?(value)
        raise(Puppet::ResourceError, "AEM Home must be fully qualified, not '#{value}'")
      end
    end
  end

  newparam(:password) do
    desc 'Password used to log into AEM.'
  end

  newparam(:retries) do
    desc 'Number of retries to communicate with AEM before giving up.'
    newvalues(/^\d+$/)

    defaultto 10

    munge(&:to_i)
  end

  newparam(:retry_timeout) do
    desc 'Seconds to wait between retries to communicate with AEM before giving up.'
    newvalues(/^\d+$/)

    defaultto 1

    munge(&:to_i)
  end

  newparam(:source) do
    desc 'The source package file to upload/install.'
  end

  newparam(:timeout) do
    desc 'Timeout for a successful AEM start. Default = 60 seconds'

    newvalues(/^\d+$/)

    defaultto 60

    munge(&:to_i)
  end

  newparam(:username) do
    desc 'Username used to log into AEM.'
  end

  validate do
    raise(Puppet::ResourceError, 'AEM Home must be specified.') if self[:home].nil? || !self[:home]
  end

end
