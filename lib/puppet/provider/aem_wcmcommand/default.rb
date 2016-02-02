require 'json'
require 'net/http'

Puppet::Type.type(:aem_wcmcommand).provide :ruby, :parent => Puppet::Provider do

  mk_resource_methods

  def initialize(resource = nil)
    super(resource)
    @wcmcommand_uri = nil
    @property_flush = {}
  end

  def create
    unless check_exists(resource[:configuration])
      post_to_wcmcommand(resource[:configuration])
    end

    @property_flush[:ensure] = :present
  end

  def exists?
    @property_hash[:ensure] = :absent

    if check_exists(resource[:configuration])
      @property_hash[:ensure] = :present
    end

    @property_hash[:ensure] == :present
  end

  def destroy
    params = {}
    params['cmd'] = 'deletePage'
    params['path'] = resource[:configuration]['parentPath'] + "/" + resource[:configuration]['label']
    params['_charset_'] = resource[:configuration]['_charset_']

    debug(params)

    post_to_wcmcommand(params)

    @property_flush[:ensure] = :absent
  end

  protected

  def wcmcommand_uri
    return @wcmcommand_uri if @wcmcommand_uri

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
    uri = "#{uri}/bin/wcmcommand"
    @wcmcommand_uri = uri
    @wcmcommand_uri
  end

  def check_exists(parameters)

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
      uri = "#{uri}#{parameters['parentPath']}"
      uri = "#{uri}/#{parameters['label']}"
      uri = URI("#{uri}")

      debug(uri)

      req = Net::HTTP::Head.new(uri.request_uri)
      req.basic_auth(resource[:username], resource[:password])
      req['Referer'] = wcmcommand_uri

      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      case res
        when Net::HTTPFound
            debug("EXISTS")
          true
        when Net::HTTPNotFound
            debug("DOES NOT EXISTS")
          false
        else
          res.value
      end
  end

  def post_to_wcmcommand(parameters)

    uri = URI("#{wcmcommand_uri}")

    req = Net::HTTP::Post.new(uri.request_uri)
    req.basic_auth(resource[:username], resource[:password])
    req.form_data = parameters
    req['Referer'] = wcmcommand_uri

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
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
