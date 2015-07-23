require 'puppet'
require 'puppet/provider/aem'

Puppet::Type.type(:aem).provide :linux, :parent => Puppet::Provider::AEM do

  self::START_ENV_FILE = 'start-env'
  self::START_FILE = 'start'
  self::STOP_FILE = 'stop'

  confine :kernel => :linux
  defaultfor :kernel => :linux

  commands :find => 'find'
  commands :java => 'java'

  mk_resource_methods

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
