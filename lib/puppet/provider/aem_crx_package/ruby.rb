
Puppet::Type.type(:aem_crx_package).provide :ruby, parent: Puppet::Provider do

  mk_resource_methods

  confine feature: :xmlsimple
  confine feature: :crx_packmgr_api_client

  def self.require_libs
    require 'crx_packmgr_api_client'
    require 'xmlsimple'
  end

  def initialize(resource = nil)
    super(resource)
    @property_flush = {}
  end

  def upload
    @property_flush[:ensure] = :present
  end

  def install
    @property_flush[:ensure] = :installed
  end

  def remove
    @property_flush[:ensure] = :absent
  end

  def retrieve
    self.class.require_libs
    find_package
    @property_hash[:ensure]
  end

  def flush
    self.class.require_libs
    case @property_flush[:ensure]
    when :absent
      result = remove_package
    when :present
      result = @property_hash[:ensure] == :absent ? upload_package : uninstall_package
    when :installed
      result = @property_hash[:ensure] == :absent ? upload_package(true) : install_package
    else
      raise "Unknown property flush value: #{@property_flush[:ensure]}"
    end
    raise_on_failure(result)
    find_package
  end

  private

  def build_cfg(port = nil, context_root = nil)
    config = CrxPackageManager::Configuration.new
    config.configure do |c|
      c.username = @resource[:username]
      c.password = @resource[:password]
      c.host = "localhost:#{port}" if port
      c.base_path = "#{context_root}/#{c.base_path}" if context_root
    end
    config
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

    config = build_cfg(port, context_root)

    @client = CrxPackageManager::DefaultApi.new(CrxPackageManager::ApiClient.new(config))
    @client
  end

  def find_package
    client = build_client

    path = "/etc/packages/#{@resource[:group]}/#{@resource[:name]}-#{@resource[:version]}.zip"
    # TODO: Need to loop/timeout for AEM not being online quite yet
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

  def upload_package(install = false)
    client = build_client
    pkg = File.new(@resource[:source])
    client.service_post(pkg, install: install)
  end

  def install_package
    client = build_client
    client.service_get('inst', group: @resource[:group], name: @resource[:name])
  end

  def uninstall_package
    client = build_client
    client.service_get('uninst', group: @resource[:group], name: @resource[:name])
  end

  def remove_package
    client = build_client
    client.service_get('rm', group: @resource[:group], name: @resource[:name])
  end

  def raise_on_failure(api_response)
    hash = XmlSimple.xml_in(api_response, ForceArray: false, KeyToSymbol: true, AttrToSymbol: true)
    response = CrxPackageManager::ServiceResponse.new
    response.build_from_hash(hash)
    raise(response.response.status[:content]) unless response.response.status[:code].to_i == 200

  end
end
