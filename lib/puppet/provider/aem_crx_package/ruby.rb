# frozen_string_literal: true

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
    @aem_root = nil
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
    check_aem
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

  def aem_root
    return @aem_root if @aem_root

    port = nil
    context_root = nil

    File.foreach(File.join(resource[:home], 'crx-quickstart', 'bin', 'start-env')) do |line|
      match = line.match(/^PORT=(\S+)/) || nil
      port = match.captures[0] if match

      match = line.match(/^CONTEXT_ROOT='(\S+)'/) || nil
      context_root = match.captures[0] if match
    end

    uri = "http://localhost:#{port}"
    uri = "#{uri}/#{context_root}" if context_root
    @aem_root = uri
    @aem_root
  end

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

  def check_aem
    uri = URI("#{aem_root}/system/console/bundles.json")
    http = Net::HTTP.new(uri.host, uri.port)
    http.set_debug_output($stdout) if Puppet[:debug]
    req = Net::HTTP::Get.new(uri.request_uri)
    req.basic_auth resource[:username], resource[:password]
    Timeout.timeout(@resource[:timeout]) do
      Kernel.loop do
        begin
          res = http.request(req)
          jsn = JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)

          # s is a status array -
          #   0 -> Total Bundles
          #   1 -> Running Bundles
          #   2 -> Running Fragments
          return true if jsn['s'][0] == jsn['s'][1] + jsn['s'][2]

          raise StopIteration
        rescue Net::HTTPServerError, Net::HTTPClientError, Net::HTTPFatalError, StopIteration
          Puppet.debug('Unable to determine AEM state, waiting for AEM to start...')
          sleep 10
        end
      end
    end
  end

  def find_package
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
    ary&.each do |p|
      found_pkg = p if p.version == @resource[:version]
      break if found_pkg
    end
    found_pkg
  end

  def upload_package(install = false)
    client = build_client
    file = File.new(@resource[:source])
    client.service_post(file, install: install)
  end

  def install_package
    client = build_client
    client.service_exec('install', @resource[:pkg], @resource[:group], @resource[:version])
  end

  def uninstall_package
    client = build_client
    client.service_exec('uninstall', @resource[:pkg], @resource[:group], @resource[:version])
  end

  def remove_package
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
