#!/usr/bin/ruby
#    This file is part of GCodeCombine.
#
#    GcodeCombine is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    GcodeCombine is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with GcodeCombine.  If not, see <http://www.gnu.org/licenses/>.



class GcodeCombine
	attr_accessor :stl_size
	def initialize
		@stl_size = [40,40] # for later
		@bed_size = [100,180] # for later
		@gcodes = []
		@settings = []
		@files_split_in_layers = []
		@z_feedrate = 7800
	end	

	def head=(filename)
		@head = strip_comment_lines(File.readlines(filename))
	end

	def tail=(filename)
		@tail = strip_comment_lines(File.readlines(filename))
	end

	def file(filename, setting)
		@gcodes << strip_head_and_tail(strip_comment_lines(File.readlines(filename)))
		@settings << setting
	end

	def strip_comment_lines(gcode)
		output = []		
		gcode.each do |line|
			if line[0] != 59 and line[0] != 10 # strip ; and \n lines
				output << line
			end
		end
		output
	end
	
	def strip_head_and_tail(gcode)
		gcode[@head.size..gcode.size-@tail.size]
	end	

	def split_by_layer(gcode)
		layer = []
		layers = []
		z_values = []
		gcode.each do |line|
			
			if line.include? "Z"		
				z = line.split[1].gsub("Z","")
				layers << layer.flatten unless layer.empty?
				z_values << z
				layer = []
			else
				layer << line	unless z_values.empty?	
			end	
		end	
		[layers, z_values]
	end

	def output
		z_values =[]
		@gcodes.each do |gcode|
			layers, z_values = split_by_layer gcode
			@files_split_in_layers << layers
			# FIXME: we should check if z values differ from the other files and die if they do
		end 
		
		output = @head # start with head
		i = 0 # layer gcode iterator
		z_values.each do |z|
			output << "G1 Z#{z} F#{@z_feedrate}\n"
			@files_split_in_layers.each_with_index do |layer,grid_position|				
				output << offset(layer[i],grid_position)
			end
			i+=1
		end

		output << @tail
		output.flatten!
		
	end

	def create_grid
		n = @gcodes.size
		x,y = @stl_size
		bed_x, bed_y = @bed_size
		@grid = []
		
		pos_x=0
		pos_y=0
		n.times do
			pos_x+=x
			if pos_x > bed_x
				pos_x = x
				pos_y += y
				# TODO: crash if it won't fit the plate
			end
			@grid << [pos_x,pos_y]		
		end			
	end

	def print_grid
		return if @grid == nil
		y = @grid.first[1]
		str = []
		@grid.each_with_index do |grid, i|
			if y != grid[1]
				puts str.join(" ")
				str = []	
				y = grid[1]		
			end
			str << @settings[i]
		end
		puts str.join(" ") unless str.size == 0
		
	end

	def offset(gcode,grid_position)
		return [] if gcode == nil
		create_grid if @grid == nil
		x, y = @grid[grid_position]
		output = []
		gcode.each do |line|
			if line.include?("G1") && line.include?("X") && line.include?("Y")
				s = line.split
				s[1] = "X"+(s[1].gsub("X","").to_f + x).to_s
				s[2] = "Y"+(s[2].gsub("Y","").to_f + y).to_s
				s << "; offset by x=#{x} y=#{y}" 
				output << s.join(" ")
			else
				output << line			
			end
		end
		output	
	end

end	


#c = GcodeCombine.new
#c.head="start.gcode"
#c.tail="end.gcode"
#c.file("1.gcode",0.7)
#c.file("2.gcode",0.8)
#c.file("3.gcode",0.9)

#f=File.open("output.gcode","w")
#f.puts c.output
#f.close

