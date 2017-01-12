
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

    def retrieve
      provider.retrieve
    end
  end

  newparam(:name, namevar: true) do
    desc 'The name of the CRX Package.'
  end

  newproperty(:group) do
    desc 'The group of the CRX Package.'
  end

  newproperty(:version) do
    desc 'The version of the CRX Package.'
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
