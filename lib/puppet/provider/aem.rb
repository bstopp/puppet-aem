class Puppet::Provider::AEM < Puppet::Provider

  def self.prefetch(resources)
    resources.keys.each do |name|
      if provider = instances.find{ |prov| prov.home == resources[name].home }
        provider.name = name
        resources[name].provider = provider
      end
    end
  end

  def flush
    @property_hash.clear
  end

  def properties
    if @property_hash.empty?
      @property_hash[:ensure] = :absent
    end
    @property_hash.dup
  end

  def exists?
    @property_hash[:ensure] == :present
  end
end
