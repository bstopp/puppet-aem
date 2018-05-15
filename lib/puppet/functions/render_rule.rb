# Puppet function to render a single rule
# it supports rendition of glob style expressions (double ") and POSIX expressions (single quoted ')
Puppet::Functions.create_function(:'render_rule') do 
  
  dispatch :render_rule do
    required_param 'Hash', :rule
    required_param 'Integer', :index
    return_type 'String'
  end

  def render_rule(rule, index) 
  
  	# index with 3 digits
    output = "/#{sprintf("%03i", index)} { /type \"#{rule['type']}\" "
  
    # glob has precedence
    if rule['glob']
      output+= "/glob \"#{rule['glob']}\" "
    else
      for param in ['method','url','query','protocol','path','suffix']
        output+= "/#{param} \"#{rule[param]}\" " if rule[param]
        output+= "/#{param} \'#{rule[param+ 'E']}\' " if rule[param + 'E'] 
      end
  
      # special handling for selectors and extensions for backward compatibility
      for param in ['selectors','extension']
        if rule[param] 
          output+= "/#{param} \'#{rule[param]}\' " 
          call_function('deprecation', 'render_rule', 
          	"Using Dispatcher rule #{param} with RegEx is deprecated and might get removed in later versions. " + 
          	"Please update to use #{param}_e instead. Rule was #{rule}.") if /[\(\)\[\]\|]/   =~ rule[param]
        end
  
        output+= "/#{param} \'#{rule[param+ 'E']}\' " if rule[param + 'E'] 
      end
  
    end
    return output + "}\n"
  
  end  

end