require 'json'
require 'net/http'

Puppet::Type.type(:aem_content).provide :ruby, :parent => Puppet::Provider do

  mk_resource_methods

  def initialize(resource = nil)
    super(resource)
    @property_flush = {}
  end

  def create
    @property_flush[:ensure] = :present
  end

  def exists?
    check_exists(resource[:name])
    @property_hash[:ensure] == :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def flush
    if @property_flush[:ensure] == :absent
      submit(resource[:name], ':operation' => 'delete')
      return
    end
    submit(resource[:name], resource[:properties])
    check_exists(resource[:name])
    @property_flush.clear
  end

  protected

  def submit(node, properties)
    uri = get_node_uri(node)
    req = Net::HTTP::Post.new(uri.request_uri)
    req.basic_auth(resource[:username], resource[:password])
    req.form_data = properties
    req['Referer'] = uri

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

  def check_exists(node)
    uri = get_node_uri(node)
    req = Net::HTTP::Head.new(uri.request_uri)
    req.basic_auth(resource[:username], resource[:password])
    req['Referer'] = uri

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    case res
    when Net::HTTPFound
      @property_hash[:ensure] = :present
    else
      @property_hash[:ensure] = :absent
    end
  end

  def get_node_uri(node)
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
    uri = "#{uri}#{node}"
    uri = URI("#{uri}")
    uri
  end
end
