# = Importing and Outputting Files
#
#
module FileIO

	require 'json'

	#Main File Exporter
	class JSONExporter

		attr_reader :file_path, :file_name, :data

		def initialize(args)
			full_path = args[:path] + '/' + args[:name]
			@file_path = File.dirname(full_path)
			@file_name = File.basename(full_path)
			@data      = args[:data]

			#Sanitize the filepath
			@file_name.gsub!('/','-')
			@file_name.gsub!(/\s/,'_')
			@file_name.gsub!(':','.')

			FileUtils.mkdir_p(file_path) unless Dir.exists? file_path

		end

		# Writes the actual json files.
		def write(passed_data = nil)
			this_data = passed_data || data
			File.open(file_path+'/'+file_name, 'wb') do |file|
				file.write( this_data.to_json )
			end
		end

		def getIndexByField(nodes, field, target)
			nodes.each_with_index do |node, index|
				if node[field] == target
					return index
				end
			end
		end

		def write_network(graph_data)
			graph_data[:edges].each do |edge|
				edge[:source] = getIndexByField( graph_data[:nodes], :id, edge[:source] )
				edge[:target] = getIndexByField( graph_data[:nodes], :id, edge[:target] )
			end
			graph_data[:links] = graph_data.delete :edges
			write(graph_data)
		end
	end


	#Write a 'gml' file for network analytics
	class GMLAuthor
		require 'htmlentities'

		attr_reader :nodes, :edges, :file, :directed, :id, :label, :comment, :filename, :encoder

		def initialize(args)
			@filename= args[:filename].to_s || Time.new.to_s + '.gml'
			@nodes = []
			@edges = []

			@id = args[:id]
			@label = args[:label]
			@comment = args[:comment]

			if args[:directed]
				@directed = 1
			else
				@directed = 0
			end

			@encoder = HTMLEntities.new

			@filename = filename#.gsub(/[^A-Za-z0-9\.\/]/,'_')

			@file = File.open(filename, 'w')
		end

		def write
			header
			write_nodes
			write_edges
			footer
		end

		def header
			file.write %Q{graph [\n}
			file.write %Q{\tdirected #{directed}\n}
			if id
				file.write %Q{\tid #{id}\n}
			end
			if label
				file.write %Q{\tlabel #{label}\n}
			end
			if comment
				file.write %Q{\tcomment #{comment}\n}
			end
		end

		def footer
			file.write %Q{]}
			file.close
		end

		def add_node(node)
			unless nodes.include? node
				@nodes << node
			end
		end


		def add_edge(edge)
			unless edges.include? edge
				@edges << edge
			end
		end

		def write_nodes
			nodes.each do |node|
				file.write %Q{\tnode [\n}
				file.write %Q{\t\tid "#{encoder.encode( (node.delete :id), :named)}"\n}
				node.keys.each do |key|
					file.write %Q{\t\t#{key} }
					if node[key].is_a? String
						file.write %Q{"#{node[key]}"\n}
					else
						file.write %Q{#{node[key]}\n}
					end
				end
				file.write %Q{\t]\n}
			end
		end

		def write_edges
			edges.each do |edge|
				file.write %Q{\tedge [\n}
				file.write %Q{\t\tsource "#{encoder.encode( (edge.delete :source), :named)}"\n}
				file.write %Q{\t\ttarget "#{encoder.encode( (edge.delete :target), :named)}"\n}
				edge.keys.each do |key|
					file.write %Q{\t\t#{key} }
					if edge[key].is_a? String
						file.write %Q{"#{edge[key]}"\n}
					else
						file.write %Q{#{edge[key]}\n}
					end
				end
				file.write %Q{\t]\n}
			end
		end
	end

	def self.unpack_objects(arg)
		return arg if arg.is_a? Numeric
		return arg if arg.is_a? String
		raise "nil" if arg.nil?

		begin
			arg.each do |bucket|
				hash_objs = []
				bucket[:objects].each do |object|
					hash = {}
					object.instance_variables.each {|var| hash[var.to_s.delete("@")] = object.instance_variable_get(var) }
					hash_objs << hash
				end
				bucket[:objects] = hash_objs
			end
			return arg
		rescue
			puts $!
			raise "error"
		end
	end
end
