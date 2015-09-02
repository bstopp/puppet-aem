require 'etc'
require 'fileutils'
require 'net/http'

Puppet::Type.type(:aem_installer).provide :default, :parent => Puppet::Provider do

  self::START_FILE = 'start'
  self::STOP_FILE = 'stop'
  self::LAUNCHPAD_NAME  = 'cq-quickstart-*-standalone*.jar'
  self::INSTALL_FIELDS  = [:home, :version]
  self::INSTALL_REGEX   = %r{^(\S+)/crx-quickstart/app/cq-quickstart-([0-9.]+)-standalone.*\.jar$}

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

  def self.prefetch(resources)

    found = instances

    resources.keys.each do |name|
      if (provider = found.find { |prov| prov.get(:home) == resources[name][:home] })
        resources[name].provider = provider
      end
    end
  end

  def initialize(resource = nil)

    super(resource)
    @exec_options = {
      :failonfail => true,
      :combine => true,
      :custom_environment => {}
    }

  end

  def properties
    @property_hash[:ensure] = :absent if @property_hash.empty?
    @property_hash.dup
  end

  def exists?
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

    path = File.join(@resource[:home], 'crx-quickstart/repository')
    FileUtils.remove_entry_secure(path)
    @property_hash.clear
  end

  def flush
    @property_hash = @resource.to_hash
  end

  protected

  def self.found_to_hash(line)
    line.strip!
    hash = {}

    if (match = self::INSTALL_REGEX.match(line))
      self::INSTALL_FIELDS.zip(match.captures) { |f, v| hash[f] = v }
      hash[:name] = hash[:home]
      hash[:ensure] = File.exist?("#{hash[:home]}/crx-quickstart/repository") ? :present : :absent

      stat = File.stat(line)

      hash[:user] = Etc.getpwuid(stat.uid).name
      hash[:group] = Etc.getgrgid(stat.gid).name

    else
      Puppet.debug("Failed to match install line #{line}")
    end

    hash
  end

  def update_exec_opts

    unless @resource[:user].nil? || @resource[:user].empty?
      user = Etc.getpwnam(@resource[:user])
      @exec_options[:uid] = user.uid
    end

    return if @resource[:group].nil? || @resource[:group].empty?

    grp = Etc.getgrnam(@resource[:group])
    @exec_options[:gid] = grp.gid

  end

  def build_bin_dir
    File.join(@resource[:home], 'crx-quickstart', 'bin')
  end

  def call_start_script
    cmd = File.join(build_bin_dir, self.class::START_FILE)
    execute(cmd, @exec_options)
  end

  # Checks the system to for a state, loops until it reaches that state
  def monitor_site(desired_state = :on)

    # If context root is not blank, need to ensure URI has a trailing slash,
    # otherwise the system redirects, thus shutting down before installation is complete.
    uri_s = "http://localhost:#{@resource[:port]}/"
    uri_s = "#{uri_s}#{@resource[:context_root]}/" if @resource[:context_root]

    uri = URI.parse(uri_s)

    Timeout.timeout(@resource[:timeout]) do

      Kernel.loop do
        begin
          response = Net::HTTP.get_response(uri)
          issuccess = response.is_a?(Net::HTTPSuccess)
          isredirect = response.is_a?(Net::HTTPRedirection) unless issuccess
          return if (issuccess || isredirect) && desired_state == :on
        rescue
          return if desired_state == :off
        end
        sleep @resource[:snooze]
      end
    end

  end

  def call_stop_script
    cmd = File.join(build_bin_dir, self.class::STOP_FILE)
    execute(cmd, @exec_options)
  end

end
