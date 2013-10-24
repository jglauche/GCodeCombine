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

require "fileutils"
require "./gcode_combine"

if ARGV.size == 0
	puts "Usage: ./calibrate.rb [path to slic3r executable] [path to slic3r config] [perimeter_value1] [perimeter_value2] ..."
	exit
end

filename="calibration_parts/perimeter_width_test" # without extension
executable = ARGV[0].to_s
config_file = ARGV[1].to_s
perimeter_values = ARGV[2..-1].map{|a| a.to_s}

unless Dir.exists? "gcode"
	Dir.mkdir "gcode"
end

puts "Slicing test prints.. "
perimeter_values.each do |width|
	puts "extrusion_width = #{width}..."
	options = "--skirts=0 --perimeter-extrusion-width=#{width}"
	system([executable, "--load ",config_file, options, filename+".stl"].join(" "))
	FileUtils.mv(filename+".gcode",["./gcode/",width, ".gcode"].join("")) 	
end
puts "Test prints sliced, combining!"

g = GcodeCombine.new
g.head="start.gcode"
g.tail="end.gcode"
g.stl_size = [25+2,6+2] # TODO: this should be gathered by slic3r.pl --info
perimeter_values.each do |width|
	g.file(["./gcode/",width, ".gcode"].join(""),width)
end

f=File.open("output.gcode","w")
f.puts g.output
f.close
puts "Calibration print prepared. Load output.gcode and hit print!"
puts "Perimeter extrusion width for each part:"
g.print_grid



