require 'etc'
require 'fileutils'
require 'net/http'

Puppet::Type.type(:aem_installer).provide :default, parent: Puppet::Provider do

  commands find: 'find'
  commands java: 'java'

  mk_resource_methods

  def initialize(resource = nil)
    super(resource)
    @exec_options = {
      failonfail: true,
      combine: true,
      custom_environment: {}
    }
    @start_file = 'start'
    @start_env_file = 'start-env'
    @stop_file = 'stop'
    @launchpad_name = 'cq-quickstart-*-standalone*.jar'
    @repository_dir = 'repository'
    @quickstart_fields = [:home, :version]
    @quickstart_regex = %r|^(\S+)/crx-quickstart/app/cq-quickstart-([0-9.]+)-standalone.*\.jar$|
    @port_regex = /^PORT=(\S+)/
    @context_root_regex = /^CONTEXT_ROOT='(\S+)'/

  end

  def exists?
    find_instance
    @property_hash[:ensure] == :present
  end

  def create
    update_exec_opts
    call_start_script
    monitor_site
    call_stop_script
    monitor_site(:off)
    @property_hash[:ensure] = :present
  end

  def destroy
    path = File.join(@resource[:home], 'crx-quickstart', @repository_dir)
    FileUtils.remove_entry_secure(path)
    @property_hash.clear
  end

  protected

  def find_instance
    hash = {}
    begin

      cmd = [command(:find).to_s, @resource[:home], "-name \"#{@launchpad_name}\"", '-type f']
      execpipe(cmd) do |process|
        process.each_line do |line|
          hash = found_to_hash(line)
        end
      end
    rescue Puppet::ExecutionFailure
      raise Puppet::Error, "Failed to find AEM instance in '#{@resource[:home]}'.", $ERROR_INFO.backtrace
    end

    @property_hash = hash.dup
    hash
  end

  def found_to_hash(line)
    line.strip!
    hash = @resource.to_hash.dup

    if (match = @quickstart_regex.match(line))
      @quickstart_fields.zip(match.captures) { |f, v| hash[f] = v }
      hash[:ensure] = File.exist?(File.join(@resource[:home], 'crx-quickstart', @repository_dir)) ? :present : :absent
      stat = File.stat(line)

      hash[:user] = Etc.getpwuid(stat.uid).name
      hash[:group] = Etc.getgrgid(stat.gid).name

    else
      Puppet.debug("Failed to match install line #{line}")
    end

    read_env(hash)
    hash
  end

  def read_env(hash)

    File.foreach(File.join(build_bin_dir, @start_env_file)) do |line|

      match = line.match(@port_regex) || nil
      hash[:port] = match.captures[0] if match

      match = line.match(@context_root_regex) || nil
      hash[:context_root] = match.captures[0] if match

    end
  end

  def build_bin_dir
    File.join(@resource[:home], 'crx-quickstart', 'bin')
  end

  # These methods should have a fully populated @property_hash
  def update_exec_opts

    user = Etc.getpwnam(@property_hash[:user])
    @exec_options[:uid] = user.uid

    grp = Etc.getgrnam(@property_hash[:group])
    @exec_options[:gid] = grp.gid

  end

  def call_start_script
    cmd = File.join(build_bin_dir, @start_file)
    execute(cmd, @exec_options)
  end

  # Checks the system to for a state, loops until it reaches that state
  def monitor_site(desired_state = :on)
    # If context root is not blank, need to ensure URI has a trailing slash,
    # otherwise the system redirects, thus shutting down before installation is complete.
    uri_s = "http://localhost:#{@property_hash[:port]}/"
    uri_s = "#{uri_s}#{@property_hash[:context_root]}/" if @property_hash[:context_root]

    uri = URI.parse(uri_s)

    Timeout.timeout(@property_hash[:timeout]) do

      Kernel.loop do
        begin
          response = Net::HTTP.get_response(uri)

          case response
          when Net::HTTPSuccess, Net::HTTPRedirection, Net::HTTPUnauthorized
            return if desired_state == :on
          end

        rescue
          return if desired_state == :off
        end
        sleep @property_hash[:snooze]
      end
    end

  end

  def call_stop_script
    cmd = File.join(build_bin_dir, @stop_file)
    execute(cmd, @exec_options)
  end

end
