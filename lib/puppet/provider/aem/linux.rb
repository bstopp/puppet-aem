require 'erb'
require 'etc'
require 'fileutils'
require 'puppet'
require 'puppet/provider/aem'
require 'net/http'

Puppet::Type.type(:aem).provide :linux, :parent => Puppet::Provider::AEM do


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
      raise Puppet::Error, 'Failed to find AEM instances.', $!.backtrace
    end

    installs
  end

  def create

    update_exec_opts
    unpack_jar
    create_env_script
    create_start_script
    call_start_script
    monitor_site
    call_stop_script

  end

  protected

  def unpack_jar
    cmd = ["#{command(:java)}",'-jar', @resource[:source], '-b', @resource[:home], '-unpack']
    execute(cmd, @exec_options)
  end

  # Find the resource instance; populate hash of values based on
  # result of find.
  #  def query
  #
  #    cmd = [@resource[:home], "-name \"#{self.class::LAUNCHPAD_NAME}\"", '-type f']
  #    found = find(cmd)
  #
  #    @property_hash.update(self.class.found_to_hash(found))
  #    @property_hash.dup
  #  end

end