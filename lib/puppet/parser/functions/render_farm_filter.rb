# Puppet parser extension to render a farm filter
module Puppet
  module Parser
    # Function definition of render_farm_filter
    module Functions
      newfunction(:render_farm_filter, type: :rvalue) do |args|
        # Validate input
        unless args.length == 1
          raise Puppet::ParseError, "render_farm_filter(): wrong number of arguments (#{args.length}; must be 1)"
        end

        unless args[0].is_a?(String)
          raise Puppet::ParseError, 'render_farm_filter(): argument should be an string.'
        end

        return args[0] if args[0].start_with?("'") && args[0].end_with?("'")
        return '"' + args[0] + '"'
      end
    end
  end
end
