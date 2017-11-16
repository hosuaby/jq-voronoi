#!jq -rf

##
# Reduces the bounding box of voronoi diagram to dimensions defined by argument box.
# Abandons sites that are outside of a new bounding box.
# This script is for debugging purpose.
# Usage:
#   ./subspace.jq --argjson box '[10, 40, 500, 420]'     # where box = [minX, minY, maxX, maxY]
#
# @input {point[]} array of points. First two points are diagram boundaries, the rest are sites
# @param box {number[4]} new dimensions of bounding box
# @output {point[]} subset of sites that are within a new bounding box
#
# @author hosuaby

##
# Tests if supplied site is within the bounding box $box.
# @input {point} site
# @param $box {number[4]} dimensions of bounding box
# @output {boolean} true is the site within the box, false if not
def within($box):
    . as [$x, $y]
    | $box as [$minX, $minY, $maxX, $maxY]

    | if $x >= $minX and $x <= $maxX and $y >= $minY and $y <= $maxY then
          .
      else
          empty
      end
;

##
# Start of script

.[2:] as $sites
| $box as [$minX, $minY, $maxX, $maxY]
| $sites
| map(select(within($box)))
| [[$minX, $minY], [$maxX, $maxY]] + .
