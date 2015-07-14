class Puppet::Provider::AEM < Puppet::Provider

  self::LAUNCHPAD_NAME  = 'cq-quickstart-*-standalone*.jar'
  self::INSTALL_FIELDS  = [:home, :version]
  self::INSTALL_REGEX   = %r{^(\S+)/crx-quickstart/app/cq-quickstart-([0-9.]+)-standalone.*\.jar$}

  def initialize(resource = nil)

    super(resource)
    @exec_options = {
      :failonfail => true,
      :combine => true,
      :custom_environment => {},
    }

  end

  def self.prefetch(resources)

    found = instances

    resources.keys.each do |name|
      if provider = found.find { |prov| prov.get(:home) == resources[name][:home] }
        resources[name].provider = provider
      end
    end
  end

  def properties
    if @property_hash.empty?
      @property_hash[:ensure] = :absent
    end
    @property_hash.dup
  end

  def exists?

    @property_hash[:ensure] == :present
    #    return false unless File.directory?(resource[:home])
    #    Dir.foreach(File.join(resource[:home], 'apps')) do |entry|
    #      return true if entry =~ /^#{resource[:home]}\/apps\/cq-quickstart.*\.jar$/
    #    end
    #
    #    return false
  end

  def destroy

    path = File.join(@resource[:home], 'crx-quickstart')
    FileUtils.remove_entry_secure(path)
  end

  protected

  def self.found_to_hash(line)
    line.strip!
    hash = {}

    if match = self::INSTALL_REGEX.match(line)
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

    return hash
  end

  def self.get_env_properties(hash)
    filename = File.join(hash[:home], 'bin', 'start-env')
    if File.file?(filename) && File.readable?(filename)
      contents = File.read(filename)
      #TODO Is there any way to make this cleaner?
      hash[:port] = $1.to_i if contents =~ /CQ_PORT=(\S+)/
      hash[:type] = $1 if contents =~ /CQ_TYPE=(\S+)/

      # Add additional configuration properties here
    end
  end

  def update_exec_opts

    unless resource[:user].nil? || resource[:user].empty?
      user = Etc.getpwnam(resource[:user])
      @exec_options[:uid] = user.uid
    end

    unless resource[:group].nil? || resource[:group].empty?
      grp = Etc.getgrnam(resource[:group])
      @exec_options[:gid] = grp.gid
    end

  end

  def get_bin_dir
    File.join(@resource[:home], 'crx-quickstart', 'bin')
  end

  def read_erb_tpl(file)

    environment = Puppet.lookup(:environments).get(Puppet[:environment])
    template = Puppet::Parser::Files.find_template(File.join('aem',"#{file}"), environment)

    tpldata = File.read(template)
    tpldata = ERB.new(tpldata).result(binding)
    tpldata
  end

  def write_erb_file(file, contents)

    File.write(file, contents)
    File.chmod(0750, file)
    File.chown(@exec_options[:uid], @exec_options[:gid], file)

  end

  def unpack_jar
    fail Puppet::Error, "Default provider cannot run jar unpack command."
  end

  def create_env_script
    filename = 'start-env'
    contents = read_erb_tpl("#{filename}.erb")
    write_erb_file(File.join(get_bin_dir(), "#{filename}"), contents)
  end

  def create_start_script

    # Move the original script.
    filename = 'start'
    start_file = File.join(get_bin_dir(), filename)
    File.rename(start_file, "#{start_file}-orig")

    contents = read_erb_tpl("#{filename}-#{@resource[:version]}.erb")
    write_erb_file(File.join(@resource[:home], 'crx-quickstart', 'bin', "#{filename}"), contents)
  end

  def call_start_script
    cmd = File.join(@resource[:home], 'crx-quickstart', 'bin', 'start')
    execute(cmd, @exec_options)
  end

  def monitor_site
    uri = URI.parse("http://localhost:#{resource[:port]}")
    responsecode = 0
    until responsecode == 200
      request = Net::HTTP.get_response(uri)
      responsecode = request.code
      sleep 10 unless responsecode == 200
    end
  end

  def call_stop_script
    cmd = File.join(@resource[:home], 'crx-quickstart', 'bin', 'stop')
    execute(cmd, @exec_options)
  end

end
