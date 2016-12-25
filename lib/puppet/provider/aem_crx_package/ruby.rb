require 'xmlsimple'
require 'crx_packmgr_api_client'

Puppet::Type.type(:aem_crx_package).provide :ruby, parent: Puppet::Provider do

  confine :feature => :aem_crx_pkg_client

  mk_resource_methods

  def initialize(resource = nil)
    super(resource)
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
    result = @property_flush[:ensure] == :absent ? remove_package : upload_package
    raise_on_failure(result)
    find_package
  end

  private

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

  def upload_package
    client = build_client
    pkg = File.new(@resource[:source])
    install = @property_flush[:ensure] == :installed
    client.service_post(pkg, install: install)
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
