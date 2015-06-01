require 'fileutils'
require 'puppet/provider/aem'

Puppet::Type.type(:aem).provide :aem, :source => :aem, :parent => Puppet::Provider::AEM do

  #mk_resource_methods

  commands :find => 'find'
  commands :java => 'java'

  
  self::LAUNCHPAD_NAME  = 'cq-quickstart-*-standalone.jar'
  self::INSTALL_REGEX   = %r{^(\S+)/crx-quickstart/app/cq-quickstart-([0-9.]+)-standalone.jar$}
  self::INSTALL_FIELDS  = [:home, :version]

  def self.instances
    installs = []

    begin
      execpipe("#{command(:find)} / -name #{self::LAUNCHPAD_NAME} -type f") do |process|
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

  def exists?
    begin
      path = "#{resource[:home]}/crx-quickstart/app/cq-quickstart-#{resource[:version]}-standalone.jar"
      File.exist?(path)
    rescue
      
    end
  end

  private

  def self.found_to_hash(line)
    line.strip!
    hash = {}

    if match = self::INSTALL_REGEX.match(line)
      self::INSTALL_FIELDS.zip(match.captures) { |f, v| hash[f] = v }
      hash[:provider] = self.name
      hash[:ensure] = :present
    else
      Puppet.debug("Failed to match install line #{line}")
    end

    return hash
  end

end