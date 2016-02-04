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
    check_exists
    @property_hash[:ensure] == :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def flush
    if @property_flush[:ensure] == :absent
      submit(':operation' => 'delete')
      return
    end
    submit(resource[:properties])
    check_exists
    @property_flush.clear
  end

  protected

  def submit(properties)
    uri = node_uri
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

  def check_exists
    uri = node_uri
    req = Net::HTTP::Head.new(uri.request_uri)
    req.basic_auth(resource[:username], resource[:password])
    req['Referer'] = uri

    Timeout.timeout(@resource[:timeout]) do
      Kernel.loop do
        begin
          res = Net::HTTP.start(uri.hostname, uri.port) do |http|
            http.request(req)
          end
          return resouce_found?(res) if res.is_a?(Net::HTTPFound || Net::HTTPNotFound)
        rescue
          Puppet.debug('Unable to get configurations, waiting for AEM to start...')
          sleep 10
        end
      end
    end
  end

  def resouce_found?(res)
    case res
    when Net::HTTPFound
      @property_hash[:ensure] = :present
      return true
    when Net::HTTPNotFound
      @property_hash[:ensure] = :absent
      return false
    end
  end

  def node_uri
    node = resource[:name]
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
    uri = URI(uri)
    uri
  end
end
