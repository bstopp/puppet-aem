class Puppet::Provider::AEM < Puppet::Provider

  def self.prefetch(installs)
  end
  
  def properties
    if @property_hash.empty?
      @property_hash[:ensure] = :absent
    end
    @property_hash.dup
  end
end
