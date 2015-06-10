require 'fileutils'
require 'puppet/provider/aem'

Puppet::Type.type(:aem).provide :aem, :source => :aem, :parent => Puppet::Provider::AEM do

  mk_resource_methods

  commands :find => 'find'
  commands :java => 'java'


  self::LAUNCHPAD_NAME  = 'cq-quickstart-*-standalone*.jar'
  self::INSTALL_REGEX   = %r{^(\S+)/crx-quickstart/app/cq-quickstart-([0-9.]+)-standalone.*\.jar$}
  self::INSTALL_FIELDS  = [:home, :version]

  def self.instances
    installs = []
    
    begin
      cmd = ["#{command(:find)}", '/', "-name \"#{self::LAUNCHPAD_NAME}\"", '-type f'] 
      execpipe(cmd) do |process|
        process.each_line do |line|
          hash = found_to_hash(line)
          installs << new(hash) unless hash.empty?
        end
      end
    rescue Puppet::ExecutionFailure
      raise Puppet::Error, 'Failed to find AEM instances.', $!.backtrace
    end

    installs
  end
  
  # Find the resource instance; populate hash of values based on
  # result of find.
  def query
    
    cmd = [@resource[:home], "-name \"#{self.class::LAUNCHPAD_NAME}\"", '-type f']
    
    found = find(cmd)
    
    @property_hash.update(self.class.found_to_hash(found))
    @property_hash.dup
  end

  def create
    opts = ['-jar', @resource[:source], '-b', @resource[:home], '-unpack']
    java(opts)
  end

  def destroy
    query if get(:home) == :absent

    FileUtils.remove_entry_secure("#{get(:home)}/crx-quickstart") unless get(:home) == :absent
  end


  private

  def self.found_to_hash(line)
    line.strip!
    hash = {}

    if match = self::INSTALL_REGEX.match(line)
      self::INSTALL_FIELDS.zip(match.captures) { |f, v| hash[f] = v }
      hash[:name] = hash[:home]
      hash[:ensure] = :present
    else
      Puppet.debug("Failed to match install line #{line}")
    end

    return hash
  end

end