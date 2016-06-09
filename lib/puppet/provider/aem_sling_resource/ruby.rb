require 'json'
require 'net/http'

Puppet::Type.type(:aem_sling_resource).provide :ruby, :parent => Puppet::Provider do

  mk_resource_methods

  def initialize(resource = nil)
    super(resource)
    @content_uri = nil
    @content_depth = 1
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

  def build_delete(is, should)

    to_delete = {}
    is.each do |key, value|
      next if ignored?(key, is)

      if !should.key?(key)
        to_delete["#{key}@Delete"] = ''
      elsif value.respond_to?(:keys) && should[key].respond_to?(:keys)
        to_delete[key] = build_delete(value, should[key])
      elsif (value.respond_to?(:keys) && !should[key].respond_to?(:keys)) ||
            (!value.respond_to?(:keys) && should[key].respond_to?(:keys))
        to_delete["#{key}@Delete"] = ''
      end
    end

    to_delete
  end

  def build_ignore_params
    hsh = remove_invalid(@property_flush[:existing_props], resource[:properties])
    flatten_hash(hsh)
  end

  def build_parameters
    params = {}
    if @property_flush[:ensure] == :absent
      params = params.merge(':operation' => 'delete')
    else
      case resource[:handle_missing]
      when :ignore
        params = params.merge(build_ignore_params)
      when :remove
        params = params.merge(build_remove_params)
      else
        raise(Puppet::ResourceError, "Invalid handle_missing value: #{resource[:handle_missing]}")
      end
    end

    params
  end

  def build_remove_params
    processed = remove_invalid(@property_flush[:existing_props], resource[:properties])
    to_delete = build_delete(@property_flush[:existing_props], processed)

    hsh = deep_merge_hash(to_delete, processed)

    flatten_hash(hsh)
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

  def deep_merge_hash(to, from)
    # Pulled straight from Stack Overflow; don't ask me to to explain it.
    # http://stackoverflow.com/questions/9381553/ruby-merge-nested-hash
    merger = lambda do |_key, v1, v2|
      if v1.is_a?(Hash) && v2.is_a?(Hash)
        v1.merge(v2, &merger)
      elsif v1.is_a?(Array) && v2.is_a?(Array)
        v1 | v2
      elsif [:undefined, nil, :nil].include?(v2)
        v1
      else
        v2
      end
    end
    to.merge(from, &merger)
  end

  def flatten_hash(orig, flattened = {}, old_path = [])
    orig.each do |key, value|

      current_path = old_path + [key]

      if value.respond_to?(:keys)
        flatten_hash(value, flattened, current_path)
      else
        flattened[current_path.join('/')] = value
      end
    end
    flattened
  end

  def get_depth(data)
    max_depth = 1
    return max_depth unless data

    depth_func = lambda do |hsh, cur_depth|
      max_depth = cur_depth if cur_depth > max_depth
      hsh.each do |_k, v|
        depth_func.call(v, cur_depth + 1) if v.is_a?(Hash)
      end
      max_depth
    end
    depth_func.call(data, 1)
  end

  def read_content
    content = current_content

    if content
      @property_hash[:properties] = content.clone
      @property_flush[:existing_props] = content.clone
      @property_hash[:ensure] = :present
    else
      @property_flush[:existing_props] = {}
      @property_hash[:ensure] = :absent
    end
  end

  def remove_invalid(is, should)
    should.delete_if do |key, value|
      remove_invalid(is[key] || {}, value) if value.respond_to?(:keys)
      ignored?(key, is)
    end
  end

  def ignored?(key, is_hsh = nil)

    ignored = resource[:ignored_properties].include?(key)

    ignored ||= !@property_flush[:existing_props].empty? &&
                !resource.force_passwords? &&
                resource[:password_properties].include?(key)

    ignored ||= resource[:protected_properties].include?(key) &&
                !is_hsh.nil? && !is_hsh[key].nil?

    ignored
  end

  def submit

    uri = URI(content_uri)

    req = Net::HTTP::Post.new(uri.request_uri)
    req.basic_auth(resource[:username], resource[:password])
    req.form_data = build_parameters
    req['Referer'] = uri.to_s

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.read_timeout = resource[:timeout]
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
