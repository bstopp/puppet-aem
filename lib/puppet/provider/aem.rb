class Puppet::Provider::AEM < Puppet::Provider

  self::LAUNCHPAD_NAME  = 'cq-quickstart-*-standalone*.jar'
  self::INSTALL_FIELDS  = [:home, :version]

  def initialize(resource = nil)

    super(resource)
    @exec_options = {
      :failonfail => true,
      :combine => true,
      :custom_environment => {},
    }

  end

#  def self.prefetch(resources)
#
#    found = instances
#
#    resources.keys.each do |name|
#      if provider = found.find{ |prov| prov.get(:home) == resources[name][:home] }
#        resources[name][:provider] = provider
#      end
#    end
#  end

  def properties
    if @property_hash.empty?
      @property_hash[:ensure] = :absent
    end
    @property_hash.dup
  end

  def exists?

    return false unless File.exists?(resource[:home])
    Dir.foreach("#{resource[:home]}/apps") do |entry|
      return true if entry =~ /^#{resource[:home]}\/apps\/cq-quickstart.*\.jar$/
    end

    return false
  end

  def destroy

    path = File.join(@resource[:home], 'crx-quickstart')
    FileUtils.remove_entry_secure(path)
  end


end
