require 'json'
require 'net/http'

Puppet::Type.type(:aem_osgi_config).provide :ruby, parent: Puppet::Provider do

  mk_resource_methods

  def initialize(resource = nil)
    super(resource)
    @config_mgr_uri = nil
    @property_flush = {}
  end

  def create
    @property_flush[:ensure] = :present
  end

  def exists?
    read_config
    @property_hash[:ensure] == :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def flush
    post_data = @property_flush[:ensure] == :absent ? { 'delete' => true } : resource[:configuration]
    post_to_cfgmgr(post_data)
    read_config
    @property_flush.clear
  end

  protected

  def read_config
    cfg_json = current_config
    if cfg_json && !cfg_json.empty?
      configuration = json_to_configuration(cfg_json)
      @property_hash[:configuration] = configuration.clone
      @property_flush[:existing_config] = configuration.clone
      @property_flush[:location] = bundle_location(cfg_json)
      @property_hash[:ensure] = :present
    else
      @property_hash[:configuration] = nil
      @property_hash[:ensure] = :absent
    end

  end

  def config_mgr_uri
    return @config_mgr_uri if @config_mgr_uri

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
    uri = "#{uri}/system/console/configMgr"
    @config_mgr_uri = uri
    @config_mgr_uri
  end

  def current_config

    pid = resource[:pid] || resource[:name]

    uri = URI("#{config_mgr_uri}/#{pid}.json")
    req = Net::HTTP::Get.new(uri.request_uri)
    req.basic_auth resource[:username], resource[:password]

    Timeout.timeout(resource[:timeout]) do
      Kernel.loop do
        begin
          res = Net::HTTP.start(uri.hostname, uri.port) do |http|
            http.request(req)
          end
          cfg = JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
          return cfg if cfg
          raise 'Invalid response encountered.'
        rescue
          Puppet.debug('Unable to get configurations, waiting for AEM to start...')
          sleep 10
        end
      end
    end
  end

  def json_to_configuration(json)
    cfg = {}
    json[0]['properties'].each do |k, v|
      if v['is_set']
        cfg[k] = v['value'] unless v['value'].nil?
        cfg[k] = v['values'] unless v['values'].nil?
      end
    end
    cfg
  end

  def bundle_location(json)
    json[0]['bundle_location']
  end

  def build_parameters(initial)

    params = {}
    if @property_flush[:ensure] != :absent
      if @property_flush[:existing_config] && resource[:handle_missing] == :merge
        params = params.merge(@property_flush[:existing_config])
      end
      params = params.merge(initial)
      params['propertylist'] = params.keys.clone.join(',')
      params['$location'] = @property_flush[:location] if @property_flush[:location]
    else
      params = params.merge(initial)
    end

    params.merge('apply' => true)
  end

  def post_to_cfgmgr(configuration)

    pid = resource[:pid] || resource[:name]

    uri = URI("#{config_mgr_uri}/#{pid}")

    req = Net::HTTP::Post.new(uri.request_uri)
    req.basic_auth(resource[:username], resource[:password])
    req.form_data = build_parameters(configuration)
    req['Referer'] = config_mgr_uri

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.read_timeout = resource[:timeout]
      http.request(req)
    end

    case res
    when Net::HTTPSuccess, Net::HTTPRedirection

      # OK
    else
      res.value
    end
  end

end
