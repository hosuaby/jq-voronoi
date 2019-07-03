#!jq -rf

import "rectangle" as rectangle;

##
# Reduces the bounding box of voronoi diagram to dimensions defined by argument box.
# Abandons sites that are outside of a new bounding box.
# This script is for debugging purpose.
# Usage:
#   ./subspace.jq --argjson box '[10, 40, 500, 420]'     # where box = [minX, minY, maxX, maxY]
#
# @input {point[]} array of points. First two points are diagram boundaries, the rest are sites
# @param box {rectangle} new dimensions of bounding box
# @output {point[]} subset of sites that are within a new bounding box
#
# @author hosuaby

##
# Start of script

.[2:] as $sites
| [ [$box[0], $box[1]], [$box[2], $box[3]] ] as $rectangle
| $box as [$minX, $minY, $maxX, $maxY]
| $sites
| map(select(rectangle::within($rectangle)))
| [[$minX, $minY], [$maxX, $maxY]] + .
