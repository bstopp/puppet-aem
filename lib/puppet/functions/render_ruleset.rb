# Puppet function to render a complete ruleset
Puppet::Functions.create_function(:'render_ruleset') do 

  dispatch :render_ruleset do
    param 'Any', :ruleset                 # if nil or empty, whole function will return void
    optional_param 'String', :rulesetname # if rulesetname is passed, section will be written /foo { }
    optional_param 'Integer', :indent     # defaults to 4
  end

  def render_ruleset(ruleset, rulesetname, indent=4) 
    # skip, if ruleset is empty. Don't even write the section
    return "" if ruleset.nil? || ruleset.empty?

    output = ""
    output+= "/#{rulesetname} {\n" if rulesetname
    ruleset.sort_by { |entry| entry['rank'] || -1 }.each_with_index do |rule, idx|
      output+= (" " * (indent+2)) + call_function('render_rule', rule, idx)
    end
    output+= (" " * indent) + "}" if rulesetname
    return output
  end

end