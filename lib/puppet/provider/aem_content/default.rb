require 'json'
require 'net/http'

Puppet::Type.type(:aem_content).provide :ruby, :parent => Puppet::Provider do

  mk_resource_methods

  def initialize(resource = nil)
    super(resource)
    @property_flush = {}
  end

  def create
      create_node(resource[:name], resource[:properties])
  end

  def exists?
    @property_hash[:ensure] = :absent

    if check_exists(resource[:name])
      @property_hash[:ensure] = :present
    end

    @property_hash[:ensure] == :present
  end

  def destroy
  end

  protected

  def create_node(node, properties)
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

    req = Net::HTTP::Post.new(uri.request_uri)
    req.basic_auth(resource[:username], resource[:password])
    req.form_data = properties
    req['Referer'] = uri

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    case res
      when Net::HTTPCreated
        true
      else
        res.value
    end
  end

  def check_exists(node)
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
    uri = "#{uri}/#{node}"
    uri = URI("#{uri}")

    req = Net::HTTP::Head.new(uri.request_uri)
    req.basic_auth(resource[:username], resource[:password])
    req['Referer'] = uri

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    case res
      when Net::HTTPFound
        true
      when Net::HTTPNotFound
        false
      else
        res.value
    end
  end
end
