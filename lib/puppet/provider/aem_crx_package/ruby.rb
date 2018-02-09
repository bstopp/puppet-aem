
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
    Puppet.debug('aem_crx_package::ruby - Upload requested.')
  end

  def install
    @property_flush[:ensure] = :installed
    Puppet.debug('aem_crx_package::ruby - Install requested.')
  end

  def remove
    @property_flush[:ensure] = :absent
    Puppet.debug('aem_crx_package::ruby - Remove requested.')
  end

  def purge
    @property_flush[:ensure] = :purged
    Puppet.debug('aem_crx_package::ruby - Purge requested.')
  end

  def retrieve
    self.class.require_libs
    find_package
    Puppet.debug("aem_crx_package::ruby - Retrieve - Property Hash: #{@property_hash}")
    @property_hash[:ensure]
  end

  def flush
    return unless @property_flush[:ensure]
    Puppet.debug('aem_crx_package::ruby - Flushing out to AEM.')
    self.class.require_libs
    case @property_flush[:ensure]
    when :purged
      if @property_hash[:ensure] == :installed
        result = uninstall_package
        raise_on_failure(result)
      end
      result = remove_package
    when :absent
      result = remove_package
    when :present
      result = @property_hash[:ensure] == :absent ? upload_package : uninstall_package
    when :installed
      result = @property_hash[:ensure] == :absent ? upload_package(true) : install_package
    else
      raise(Puppet::ResourceError, "Unknown property flush value: #{@property_flush[:ensure]}")
    end
    raise_on_failure(result)
    find_package
    @property_flush.clear
  end

  private

  def build_cfg(port = nil, context_root = nil)
    config = CrxPackageManager::Configuration.new
    config.configure do |c|
      c.username = @resource[:username]
      c.password = @resource[:password]
      c.timeout = @resource[:timeout]
      c.host = "localhost:#{port}" if port
      c.base_path = "#{context_root}#{c.base_path}" if context_root
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

  def wait_for_install_ok
    require 'uri'
    require 'json'
    require 'net/http'
    retries ||= @resource[:retries]
    retry_timeout = @resource[:retry_timeout]
    host = 'http://localhost:4502'
    path = '/system/sling/monitoring/mbeans/org/apache/sling/installer/Installer/Sling+OSGi+Installer.json'
    uri = URI.parse(host + path)
    request = Net::HTTP::Get.new(uri)
    request.basic_auth(@resource[:username], @resource[:password])

    # try http get of Sling+OSGi+Installer info...
    # retry untill http 200 or Timeout
    # check untill "Active":false and "ActiveResourceCount":0 or untill Timeout
    begin
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end
      data = JSON.parse(response.body)
      # Maybe we will need to check for more than 1 ok result
      # when installing some packages can trigger install of sub-packages...
      if data['Active'] == true || data['ActiveResourceCount'] != 0
        raise "Active: #{data['Active']} (req: false), ActiveResourceCount: #{data['ActiveResourceCount']} (req: 0)"
      end
    rescue Errno::EADDRNOTAVAIL, JSON::ParserError, RuntimeError => e
      Puppet.info("wait_for_install_ok FAIL for Aem_crx_package[#{@resource[:pkg]}]: #{e.class} : #{e.message} :")
      will_retry = (retries -= 1) >= 0
      if will_retry
        Puppet.debug("Waiting #{retry_timeout} seconds before retrying installer state query")
        sleep retry_timeout
        Puppet.debug("Retrying installer state query; remaining retries: #{retries}")
        retry
      end
      raise
    end
  end

  def find_package
    wait_for_install_ok
    client = build_client

    path = "/etc/packages/#{@resource[:group]}/#{@resource[:pkg]}-.zip"
    begin
      retries ||= @resource[:retries]
      retry_timeout = @resource[:retry_timeout]
      data = client.list(path: path, include_versions: true)
    rescue CrxPackageManager::ApiError => e
      Puppet.info("Unable to find package for Aem_crx_package[#{@resource[:pkg]}]: #{e}")
      will_retry = (retries -= 1) >= 0
      if will_retry
        Puppet.debug("Waiting #{retry_timeout} seconds before retrying package lookup")
        sleep retry_timeout
        Puppet.debug("Retrying package lookup; remaining retries: #{retries}")
        retry
      end
      raise
    end

    found_pkg = find_version(data.results)
    Puppet.debug("aem_crx_package::ruby - Found package: #{found_pkg}")
    if found_pkg
      @property_hash[:pkg] = found_pkg.name
      @property_hash[:group] = found_pkg.group
      @property_hash[:version] = found_pkg.version
      @property_hash[:ensure] = found_pkg.last_unpacked ? :installed : :present
    else
      @property_hash[:ensure] = :absent
    end
  end

  def find_version(ary)
    found_pkg = nil
    ary && ary.each do |p|
      found_pkg = p if p.version == @resource[:version]
      break if found_pkg
    end
    found_pkg
  end

  def upload_package(install = false)
    wait_for_install_ok
    client = build_client
    file = File.new(@resource[:source])
    client.service_post(file, install: install)
  end

  def install_package
    wait_for_install_ok
    client = build_client
    client.service_exec('install', @resource[:pkg], @resource[:group], @resource[:version])
  end

  def uninstall_package
    wait_for_install_ok
    client = build_client
    client.service_exec('uninstall', @resource[:pkg], @resource[:group], @resource[:version])
  end

  def remove_package
    wait_for_install_ok
    client = build_client
    client.service_exec('delete', @resource[:pkg], @resource[:group], @resource[:version])
  end

  def raise_on_failure(api_response)
    if api_response.is_a?(CrxPackageManager::ServiceExecResponse)
      raise(api_response.msg) unless api_response.success
    else
      hash = XmlSimple.xml_in(api_response, ForceArray: false, KeyToSymbol: true, AttrToSymbol: true)
      response = CrxPackageManager::ServiceResponse.new
      response.build_from_hash(hash)
      raise(response.response.status[:content]) unless response.response.status[:code].to_i == 200
    end
  end
end
