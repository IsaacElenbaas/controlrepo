#!/usr/bin/env ruby

require "deep_merge"

Puppet::Functions.create_function(:my_hiera) do
	dispatch :my_hiera do
		param "Hash", :options
		param "Puppet::LookupContext", :context
	end

	# puppet data_hash backend
	# see https://puppet.com/docs/puppet/5.5/hiera_custom_backends.html#data_hash_backends
	def my_hiera(options, context)
		hiera = {}
		# data written first takes priority in hiera.yaml, but everything is reversed here due to deep_merge (see below)
		options["mapped_paths"].reverse.each do |mapped_path|
			facets = context.interpolate("%{#{mapped_path[0]}}")
			if facets.nil? || facets.empty?
				Puppet.warning("[puppet::my_hiera]: #{mapped_path[0]} fact does not exist, skipping")
			else
				JSON.parse(facets).reverse.each do |facet|
					path = context.interpolate(
  						#"%{puppet_settings.main.environmentpath}/#{options["datadir"]}/#{mapped_path[2]}"
  						"%{environmentpath}/#{options["datadir"]}/#{mapped_path[2]}"
						.gsub("\#{#{mapped_path[1]}}", "#{facet}")
					)
					unless File.exist?(path)
						Puppet.warning("[puppet::my_hiera]: #{path}: file not found")
						next
					end

					# see https://github.com/danielsdeleo/deep_merge/blob/master/lib/deep_merge/core.rb
					# left takes priority, stored in right
					DeepMerge.deep_merge!(call_function("yaml_data", { "path" => path }, context), hiera)
				end
			end
		end
		return hiera
	end
end
