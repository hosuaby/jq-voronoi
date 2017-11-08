#!jq -f

import "fortune" as fortune;

##
# Calculates voronoi diagram from supplied array of sites.
# Example:
#       echo '[[0,0], [10,10], [2,1.5], [6,1], [9,2], [4.5,4], [2.5,6.5], [6.5,8]]' | ./voronoi.jq
#
# @input {point[]} array of points. First two points are diagram boundaries, the rest are sites
#
# @author hosuaby
[ .[0], . [1] ] as $boundaries
| .[2:] as $sites
| $sites
| fortune::fortune($boundaries)
