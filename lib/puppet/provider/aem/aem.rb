require 'erb'
require 'etc'
require 'fileutils'
require 'puppet'
require 'puppet/provider/aem'
require 'net/http'

Puppet::Type.type(:aem).provide :aem, :source => :aem, :parent => Puppet::Provider::AEM do

  mk_resource_methods

  defaultfor :kernel => :linux
  
  commands :find => 'find'
  commands :java => 'java'

  self::LAUNCHPAD_NAME  = 'cq-quickstart-*-standalone*.jar'
  self::INSTALL_REGEX   = %r{^(\S+)/crx-quickstart/app/cq-quickstart-([0-9.]+)-standalone.*\.jar$}
  self::INSTALL_FIELDS  = [:home, :version]

  def initialize(resource = nil)

    super(resource)
    @exec_options = {
      :failonfail => true,
      :combine => true,
      :custom_environment => {},
    }

  end

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
    cmd = ["#{command(:java)}",'-jar', @resource[:source], '-b', @resource[:home], '-unpack']
    execute(cmd, @exec_options)

    create_cfg_script
    create_start_script
#    call_start_script
#    monitor_site
#    call_stop_script

  end

  

  def destroy
    query if @resoruce[:home] == :absent

    FileUtils.remove_entry_secure("#{@resource[:home]}/crx-quickstart") unless get(:home) == :absent
  end

  private

  def get_bin_dir
    "#{@resource[:home]}/crx-quickstart/bin"
  end

  # Find the resource instance; populate hash of values based on
  # result of find.
  def query

    cmd = [@resource[:home], "-name \"#{self.class::LAUNCHPAD_NAME}\"", '-type f']
    found = find(cmd)

    @property_hash.update(self.class.found_to_hash(found))
    @property_hash.dup
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

  def read_erb_tpl(file)
    environment = Puppet.lookup(:environments).get(Puppet[:environment])
    template = Puppet::Parser::Files.find_template("aem/#{file}", environment)

    tpldata = File.read(template)
    tpldata = ERB.new(tpldata).result(binding)
    tpldata
  end

  def write_erb_file(file, contents)

    File.write(file, contents)
    File.chmod(0750, file)

    File.chown(@exec_options[:uid], @exec_options[:gid], file)

  end

  def create_cfg_script
    filename = 'start-config'
    contents = read_erb_tpl("#{filename}.erb")
    write_erb_file("#{get_bin_dir()}/#{filename}", contents)
  end

  def create_start_script

    # Move the original script.
    start_file = "#{get_bin_dir()}/start"
    File.rename(start_file, "#{start_file}-orig")

    filename = 'start'
    contents = read_erb_tpl("#{filename}.erb")
    write_erb_file("#{@resource[:home]}/crx-quickstart/bin/#{filename}", contents)
  end

  def call_start_script

    cmd = "#{@resource[:home]}/crx-quickstart/bin/start"
    execute(cmd, @exec_options)
  end

  def monitor_site
    uri = URI.parse("http://localhost:4502")
    responsecode = 0
    until responsecode == 200 
      request = Net::HTTP.get_response(uri)
      responsecode = request.code
      sleep 10 unless responsecode == 200
    end
  end

  def call_stop_script
    cmd = "#{@resource[:home]}/crx-quickstart/bin/stop"

    execute(cmd, @exec_options)
  end

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

    else
      Puppet.debug("Failed to match install line #{line}")
    end

    return hash
  end
end