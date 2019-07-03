module "rectangle";

import "point" as point;
import "line" as line;

##
# Module for work with rectangles.
#
# type rectangle = [
#     point,    // top-left corner
#     point     // bottom-right corner
# ]
#
# @author hosuaby

##
# Calculates the minimal box that encloses all supplied points.
# @input {[point]} non-empty array of points
# @output {rectangle} enclosing rectangle
def box:
    ( map(point::x) | min ) as $x1
    | ( map(point::x) | max ) as $x2
    | ( map(point::y) | min ) as $y1
    | ( map(point::y) | max ) as $y2

    | [ [$x1, $y1], [$x2, $y2] ]
;

##
# Tests if supplied site is within the bounding box.
# @input {point} site
# @param $box {rectangle} bounding box
# @output {boolean} true is the site within the box, false if not
def within($box):
    . as [$x, $y]
    | $box as [ [$minX, $minY], [$maxX, $maxY] ]

    | if $x >= $minX and $x <= $maxX and $y >= $minY and $y <= $maxY then
          .
      else
          empty
      end
;

##
# Tests if supplied point lays completely (not on the border) of parameter rectangle.
# @input {point} point
# @param $rectangle {rectangle} enclosing rectangle
# @output {boolean} true - point inside the rectangle, false - not inside rectangle
def is_inside($rectangle):
    . as [ $x, $y ]
    | $rectangle as [ [$minX, $minY], [$maxX, $maxY] ]

    | $x > $minX
      and $x < $maxX
      and $y > $minY
      and $y < $maxY
;

##
# Returns center of supplied rectangle.
# @input {rectangle} rectangle
# @output {point} center of rectangle
def center:
    line::midpoint
;

##
# Converts rectangle to polygon.
# @input {rectangle} rectangle
# @output {polygon} polygon.
def to_polygon:
    . as [ [$minX, $minY], [$maxX, $maxY] ]
    | [ [$minX, $minY], [$minX, $maxY], [$maxX, $maxY], [$maxX, $minY] ]
;
