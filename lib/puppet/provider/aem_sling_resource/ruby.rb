require 'json'
require 'net/http'

Puppet::Type.type(:aem_sling_resource).provide :ruby, :parent => Puppet::Provider do

  mk_resource_methods

  def initialize(resource = nil)
    super(resource)
    @content_uri = nil
    @content_depth = 0
    @property_flush = {}
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

      when :merge

      when :remove
      else
        fail(Puppet::ResourceError, "Invalid handle_missing value: #{resource[:handle_missing]}")
      end
    else
      params = { ':operation' => 'delete' }
    end
    params
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
