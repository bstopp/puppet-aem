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

  def self.get_env_properties(hash)
    filename = File.join(hash[:home], 'crx-quickstart', 'bin', self::START_ENV_FILE)
    if File.file?(filename) && File.readable?(filename)
      contents = File.read(filename)
      # TODO: Is there any way to make this cleaner?

      hash[:port] = $1.to_i if contents =~ /PORT=(\S+)/
      hash[:type] = $1.intern if contents =~ /TYPE=(\S+)/
      hash[:runmodes] = $1.split(',') if contents =~ /RUNMODES=(\S+)/

      # Add additional configuration properties here
    end
  end

end
