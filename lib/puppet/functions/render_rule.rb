# Puppet function to render a single rule
# it supports rendition of glob style expressions (double ") and POSIX expressions (single quoted ')
Puppet::Functions.create_function(:render_rule) do

  dispatch :render_rule do
    required_param 'Hash', :rule
    required_param 'Integer', :index
    return_type 'String'
  end

  def render_rule(rule, index)
    # index with 3 digits
    output = "/#{format('%03i', index)} { /type \"#{rule['type']}\" "

    # glob has precedence
    if rule['glob']
      output += "/glob \"#{rule['glob']}\" "
    else
      %w[method url query protocol path suffix].each do |param|
        output += "/#{param} \"#{rule[param]}\" " if rule[param]
        output += "/#{param} \'#{rule[param + '_e']}\' " if rule[param + '_e']
      end
      # special handling for selectors and extensions for backward compatibility
      %w[selectors extension].each do |param|
        send_deprecated(rule, param) if /[\(\)\[\]\|]/ =~ rule[param]
        output += "/#{param} \'#{rule[param]}\' " if rule[param]
        output += "/#{param} \'#{rule[param + '_e']}\' " if rule[param + '_e']
      end
    end
    output + "}\n"
  end

  def send_deprecated(rule, param)
    message = "Using Dispatcher rule #{param} with RegEx is deprecated and might get removed in later versions. " \
      "Please update to use #{param}_e instead. Rule was #{rule}."
    call_function('deprecation', 'render_rule', message)
  end

end
