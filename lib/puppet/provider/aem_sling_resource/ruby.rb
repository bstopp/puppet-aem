require 'json'
require 'net/http'
require 'rest-client'

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
      params = { :multipart => true }
      case resource[:handle_missing]
      when :ignore
        params = params.merge(build_ignore_params)
      when :merge
        params = params.merge(build_merge_params)
      when :remove
        params = params.merge(build_remove_params)
      else
        fail(Puppet::ResourceError, "Invalid handle_missing value: #{resource[:handle_missing]}")
      end
    else
      params = params.merge(':operation' => 'delete')
    end

    params
  end

  def build_ignore_params
    flatten_params(resource[:properties])
  end

  def build_merge_params
    params = @property_flush[:existing_props] if @property_flush[:existing_props]
    params.merge(resource[:properties])
  end

  def build_remove_params
    params = resource[:properties]
    if @property_flush[:existing_props]
      @property_flush[:existing_props].each do |k, v|
        unless params.key?(_k) || @protected_properties.include?(k)
          params["#{k}@Delete"] = v
        end
      end
    end
  end

  def build_headers
    headers = { 'Referer' => content_uri }
    if @property_flush[:ensure] == :present
      headers.merge(:content_type => 'multipart/form-data')
    end
    headers
  end

  def flatten_params(orig, flattened = {}, old_path = [])
    orig.each do |key, value|
      current_path = old_path + [key]

      if !value.respond_to?(:keys)
        flattened[current_path.join('/')] = value
      else
        flatten_params(value, flattened, current_path)
      end
    end

    flattened
  end

  def submit

    restclient = RestClient::Resource.new(content_uri, :user => resource[:username], :password => resource[:password])
    restclient.post(build_parameters, build_headers)
  rescue => e
    e.code

    # This is probably all useless now.
    # uri = URI(content_uri)
    # req = Net::HTTP::Post.new(uri.request_uri)
    # req.basic_auth(resource[:username], resource[:password])
    # req.body = build_parameters
    # req.content_type = 'multipart/form-data'
    # req['Referer'] = uri.to_s
    # res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    # http.request(req)
    # end
    # case res
    # when Net::HTTPCreated, Net::HTTPOK
    #  # OK
    # else
    #  res.value
    # end
  end
end
