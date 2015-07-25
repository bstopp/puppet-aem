require 'erb'
require 'etc'
require 'fileutils'
require 'net/http'

# Base provider logic which is platform agnostic.
class Puppet::Provider::AEM < Puppet::Provider

  self::LAUNCHPAD_NAME  = 'cq-quickstart-*-standalone*.jar'
  self::INSTALL_FIELDS  = [:home, :version]
  self::INSTALL_REGEX   = %r{^(\S+)/crx-quickstart/app/cq-quickstart-([0-9.]+)-standalone.*\.jar$}

  self::NO_SAMPLE_CONTENT = 'nosamplecontent'

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
    @property_flush = {}

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
    unpack_jar
    create_env_script
    create_start_script
    call_start_script
    monitor_site
    call_stop_script
    monitor_site(:off)
    @property_hash[:ensure] = :present
    @property_flush[:method] = :create
  end

  def destroy

    path = File.join(@resource[:home], 'crx-quickstart')
    FileUtils.remove_entry_secure(path)
    @property_hash.clear
    @property_flush[:method] = :destroy
  end

  def flush
    create_env_script unless @property_flush[:method]
    @property_hash = @resource.to_hash
    @property_flush.clear
  end

  protected

  def self.found_to_hash(line)
    line.strip!
    hash = {}

    if (match = self::INSTALL_REGEX.match(line))
      self::INSTALL_FIELDS.zip(match.captures) { |f, v| hash[f] = v }
      hash[:name] = hash[:home]
      hash[:ensure] = :present

      stat = File.stat(line)

      hash[:user] = Etc.getpwuid(stat.uid).name
      hash[:group] = Etc.getgrgid(stat.gid).name

      get_env_properties(hash)
    else
      Puppet.debug("Failed to match install line #{line}")
    end

    hash
  end

  def self.get_env_properties(hash)
    filename = File.join(hash[:home], 'crx-quickstart', 'bin', self::START_ENV_FILE)
    if File.file?(filename) && File.readable?(filename)
      contents = File.read(filename)
      populate_hash(hash, contents)
    end
  end

  def self.populate_hash(hash, contents)

    # TODO: Is there any way to make this cleaner?
    hash[:port] = $1.to_i if contents =~ /\sPORT=(\d+)\s/
    hash[:type] = $1.to_sym if contents =~ /\sTYPE=(\S+)\s/
    hash[:runmodes] = $1.split(',') if contents =~ /\sRUNMODES='(\S+)'\s/
    hash[:sample_content] = :true
    hash[:debug_port] = $1.to_i if contents =~ /\sDEBUG_PORT=(\d+)\s/

    if contents =~ /\sSAMPLE_CONTENT='(#{self::NO_SAMPLE_CONTENT})'\s/
      hash[:sample_content] = :false
    end

    hash[:context_root] = $1 if contents =~ /\sCONTEXT_ROOT='(.+?)'\s/
    hash[:jvm_mem_opts] = $1 if contents =~ /\sJVM_MEM_OPTS='(.+?)'\s/
    hash[:jvm_opts] = $1 if contents =~ /\sJVM_OPTS='(.+?)'\s/
    # Add additional configuration properties here
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

  def read_erb_tpl(file)

    environment = Puppet.lookup(:environments).get(Puppet[:environment])
    template = Puppet::Parser::Files.find_template(File.join('aem', "#{file}"), environment)

    tpldata = File.read(template)
    tpldata = ERB.new(tpldata).result(binding)
    tpldata
  end

  def write_erb_file(file, contents)

    f = File.new(file, 'w')
    f.write(contents)
    f.close
    File.chmod(0750, file)
    File.chown(@exec_options[:uid], @exec_options[:gid], file)

  end

  def unpack_jar
    cmd = ["#{command(:java)}", '-jar', @resource[:source], '-b', @resource[:home], '-unpack']
    execute(cmd, @exec_options)
  end

  def create_env_script
    filename = self.class::START_ENV_FILE
    contents = read_erb_tpl("#{filename}.erb")
    write_erb_file(File.join(build_bin_dir, "#{filename}"), contents)
  end

  def create_start_script

    # Move the original script.
    filename = self.class::START_FILE
    start_file = File.join(build_bin_dir, filename)
    File.rename(start_file, "#{start_file}-orig")

    contents = read_erb_tpl("#{filename}.erb")
    write_erb_file(File.join(@resource[:home], 'crx-quickstart', 'bin', "#{filename}"), contents)
  end

  def call_start_script
    cmd = File.join(@resource[:home], 'crx-quickstart', 'bin', self.class::START_FILE)
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
          return if ((response.is_a? Net::HTTPSuccess) ||
                      (response.is_a? Net::HTTPRedirection)) && desired_state == :on
        rescue
          return if desired_state == :off
        end
        sleep @resource[:snooze]
      end
    end

  end

  def call_stop_script
    cmd = File.join(@resource[:home], 'crx-quickstart', 'bin', self.class::STOP_FILE)
    execute(cmd, @exec_options)
  end

end
