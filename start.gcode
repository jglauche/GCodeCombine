M107
M104 S200 ; set temperature
G28 ; home all axes
M109 S200 ; wait for temperature to be reached
G90 ; use absolute coordinates
G21 ; set units to millimeters
G92 E0
M82 ; use absolute distances for extrusion
G1 F1800.000 E-1.00000
G92 E0
