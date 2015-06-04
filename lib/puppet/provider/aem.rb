class Puppet::Provider::AEM < Puppet::Provider

  def self.prefetch(resources)
    resources.keys.each do |name|
      if provider = instances.find{ |prov| prov.home == resources[name].home }
        resources[name].provider = provider
      end
    end
  end

  def properties
    if @property_hash.empty?
      @property_hash[:ensure] = :absent
    end
    @property_hash.dup
  end

  def exists?

    instances.each do |inst|
      return true if inst[:home] == @property_hash[:home]
    end

    return false;
  end
end
