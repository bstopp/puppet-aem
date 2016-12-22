require 'crx_packmgr_api_client'

Puppet::Type.type(:aem_crx_package).provide :ruby, parent: Puppet::Provider do

  mk_resource_methods

  def initialize(resource = nil)
    super(resource)
    @pack_mgr_uri = nil
    @property_flush = {}
  end

  def exists?
    find_package
    @property_hash[:ensure] == :present || @property_hash[:ensure] == :installed
  end

  def create
    @property_flush[:ensure] = :present
  end

  def install
    @property_flush[:ensure] = :installed
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def flush
    raise('Not yet implemented.')
  end

  private

  def find_package
    client = build_client

    path = "/etc/packages/#{@resource[:group]}/#{@resource[:name]}-#{@resource[:version]}.zip"
    data = client.list(path: path)

    if data.total == 1
      pkg = data.results[0]
      @property_hash[:group] = pkg.group
      @property_hash[:version] = pkg.version
      @property_hash[:ensure] = pkg.last_unpacked ? :installed : :present
    else
      @property_hash[:ensure] = :absent
    end
  end

  def build_client

    return @client if @client

    port = nil
    context_root = nil

    File.foreach(File.join(@resource[:home], 'crx-quickstart', 'bin', 'start-env')) do |line|
      match = line.match(/^PORT=(\S+)/) || nil
      port = match.captures[0] if match

      match = line.match(/^CONTEXT_ROOT='(\S+)'/) || nil
      context_root = match.captures[0] if match
    end

    config = CrxPackageManager::Configuration.new
    config.configure do |c|
      c.host = "localhost:#{port}" if port
      c.base_path = "#{context_root}/#{c.base_path}" if context_root
    end

    @client = CrxPackageManager::DefaultApi.new(CrxPackageManager::ApiClient.new(config))
    @client
  end

end
