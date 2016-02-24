require 'json'
require 'net/http'
require 'httpclient'

Puppet::Type.type(:aem_sling_resource).provide :ruby, :parent => Puppet::Provider do

  mk_resource_methods

  def initialize(resource = nil)
    super(resource)
    @content_uri = nil
    @content_depth = 0
    @property_flush = {}
    @ignored_properties = ['jcr:created', 'jcr:createdBy']
    @protected_properties = ['jcr:primaryType']
  end

  def create
    @property_flush[:ensure] = :present
  end

  def exists?
    read_content
    @property_hash[:ensure] == :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def flush
    if @property_flush[:ensure] == :absent
      submit
      return
    end
    submit
    read_content
    @property_flush.clear
  end

  protected

  def read_content
    content = current_content
    if content
      @property_hash[:properties] = content.clone
      @property_flush[:existing_props] = content.clone
      @property_hash[:ensure] = :present
    else
      @property_hash[:ensure] = :absent
    end
  end

  def content_uri

    return @content_uri if @content_uri

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
    path = resource[:path] || resource[:name]
    uri = "#{uri}#{path}"
    @content_uri = uri
    @content_uri
  end

  def current_content

    depth = get_depth(resource[:properties])

    uri = URI("#{content_uri}.#{depth}.json")
    req = Net::HTTP::Get.new(uri.request_uri)
    req.basic_auth resource[:username], resource[:password]

    Timeout.timeout(@resource[:timeout]) do
      Kernel.loop do
        begin
          res = Net::HTTP.start(uri.hostname, uri.port) do |http|
            http.request(req)
          end
          jsn = JSON.parse(res.body) if res.is_a?(Net::HTTPSuccess)
          return jsn
        rescue
          Puppet.debug('Unable to get configurations, waiting for AEM to start...')
          sleep 10
        end
      end
    end
  end

  def get_depth(data)
    max_depth = 0
    depth_func = lambda do |hsh, cur_depth|
      max_depth = cur_depth if cur_depth > max_depth
      hsh.each do |_k, v|
        depth_func.call(v, cur_depth + 1) if v.is_a?(Hash)
      end
      max_depth
    end
    depth_func.call(data, 0)
  end

  def build_parameters
    params = {}
    if @property_flush[:ensure] == :present
      case resource[:handle_missing]
      when :ignore
        params = params.merge(build_ignore_params)
      when :remove
        params = params.merge(build_remove_params)
      else
        raise(Puppet::ResourceError, "Invalid handle_missing value: #{resource[:handle_missing]}")
      end
    else
      params = params.merge(':operation' => 'delete')
    end

    params
  end

  def build_ignore_params
    flatten_params(resource[:properties], @property_flush[:existing_props])
  end

  def build_remove_params
    params = {}
    if @property_flush[:existing_props]
      @property_flush[:existing_props].each do |k, v|
        unless params.key?(k) || @protected_properties.include?(k) || @ignored_properties.include?(k)
          params["#{k}@Delete"] = v
        end
      end
    end

    params.merge(resource[:properties])
  end

  def build_headers
    { 'Referer' => content_uri }
  end

  def flatten_params(orig, current, flattened = {}, old_path = [])
    orig.each do |key, value|

      next if @ignored_properties.include?(key)
      next if @protected_properties.include?(key) && current.key?(key) && value != current[key]

      current_path = old_path + [key]

      if value.respond_to?(:keys)
        flatten_params(value, current[key] || {}, flattened, current_path)
      else
        flattened[current_path.join('/')] = value
      end
    end
    flattened
  end

  def remove_protected_properties(parameters)
    parameters.each do |key, value|
      
      if @protected_properties.contains(key.split('/').last)
        
      end
    end
  end

  def submit

    uri = URI(content_uri)
    req = Net::HTTP::Post.new(uri.request_uri)
    req.basic_auth(resource[:username], resource[:password])
    req.form_data = build_parameters
    req['Referer'] = uri.to_s
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    case res
    when Net::HTTPCreated, Net::HTTPOK
      # OK
    else
      res.value
    end
  end
end
