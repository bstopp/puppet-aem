require 'puppet'
require 'puppet/provider/aem_installer'

Puppet::Type.type(:aem_installer).provide :linux, :parent => Puppet::Provider::AemInstaller do

  self::START_FILE = 'start'
  self::STOP_FILE = 'stop'

  confine :kernel => :linux
  defaultfor :kernel => :linux

  commands :find => 'find'
  commands :java => 'java'

  mk_resource_methods

  # This is here only because of the find command.
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
      raise Puppet::Error, 'Failed to find AEM instances.', $ERROR_INFO.backtrace
    end

    installs
  end

end
