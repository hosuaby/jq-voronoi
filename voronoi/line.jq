module "line";

include "helpers";

import "point" as point;

##
# Module for work with lines.
#
# type segment = [ point, point ];      // line segment
#
# @author hosuaby

##
# Evaluates gradient-intercept line equation for supplied input.
# Function accepts two forms of line:
#   1) y = mx + b
#   2) x = my + c
# @input {[ number, number ]} line in gradient-intercept form
# @param $val {number} value for which equation must be evaluated
# @output {number} result of evaluation of equation
def eval($val):
    . as [ $slope, $intercept ]
    | $slope * $val + $intercept
;

##
# Calculates midpoint of a line segment.
# @input {segment} line segment
# @output {point} midpoint of the line segment
# @see http://www.purplemath.com/modules/midpoint.htm
def midpoint:
    [
        ( (.[0] | point::x) + (.[1] | point::x) ) / 2,
        ( (.[0] | point::y) + (.[1] | point::y) ) / 2
    ]
;

##
# Tests if supplied line segment is vertical.
# @input {segment} line segment
# @output {boolean} true - if line segment is vertical, false if not
def is_vertical:
    ( .[0] | point::x ) as $x1
    | ( .[1] | point::x ) as $x2
    | $x1 == $x2
;

##
# Tests if supplied line segment is horizontal.
# @input {segment} line segment
# @output {boolean} true - if line segment is horizontal, false if not
def is_horizontal:
    ( .[0] | point::y ) as $y1
    | ( .[1] | point::y ) as $y2
    | $y1 == $y2
;

##
# Calculates slope of supplied line segment.
# @input {segment} line segment
# @output {number} slope of line segment
def slope:
    ( .[0] | point::x ) as $x1
    | ( .[0] | point::y ) as $y1
    | ( .[1] | point::x ) as $x2
    | ( .[1] | point::y ) as $y2

    | if $x1 != $x2 then
          ( $y2 - $y1 ) / ( $x2 -$x1 )
      else
          error("Slope cannot be counted for vertical line")
      end
;

##
# Calculates gradient-intercept form of the line that pass through two points supplied as input.
# Gradient-intercept form of the line:
#       y = mx + b
#       where m - slope & b - intercept
# @input {segment} line segment
# @output {[ number, number ]} respectively m & b of gradient-intercept of the line
# @see https://www.mathplanet.com/education/algebra-1/formulating-linear-equations/writing-linear-equations-using-the-slope-intercept-form
def to_gradient_intercept_form:
    ( try
          slope
      catch
          error("Vertical line cannot be expressed in Gradient-Intercept form") ) as $slope
    | ( .[0] | point::x ) as $x1
    | ( .[0] | point::y ) as $y1

    # b = y - mx
    | ( $y1 - $slope * $x1 ) as $intercept

    | [ $slope, $intercept ]
;

##
# Calculates equation of perpendicular line of the line expressed in gradient-intercept form.
# @input {[ number, number ]} line in gradient-intercept form
# @param {point} point through which perpendicular must pass
# @output {[ number, number ]} perpendicular line in gradient-intercept form
# @see http://www.purplemath.com/modules/strtlneq3.htm
def perpendicular($point):
    . as [ $m ]

    | if $m == 0 then
          error("Impossible to express in Gradien-Intercept form line perpendicular to horizontal line")
      else
          .
      end

    # Perpendicular slope: -1/m
    | ( -1 / $m ) as $slope

    # b = y - mx
    | ( $point | point::x ) as $x
    | ( $point | point::y ) as $y
    | ( $y - $slope * $x ) as $intercept

    | [ $slope, $intercept ]
;

##
# Transforms gradient-intercept form of the line y = mx + b into form x = 1/m * y - c.
# We will calculate the equation of the same line by y:
#     y = mx + b
#     x = 1/m (y-b)
#     x = 1/m * y - c   where c = 1/m * b
# @input {[ number, number ]} line in gradient-intercept form
# @output {[ number, number ]} gradient-intercept form of the line by y
def form_by_y:
    . as [ $m, $b ]

    | if $m != 0 then
          ( 1 / $m ) as $inverted_slope
          | ( -1 * $inverted_slope * $b ) as $minus_c

          | [ $inverted_slope, $minus_c ]
      else
          error("Horizontal line can not be expressed in form x = 1/m * y - c")
      end
;

##
# Tests if supplied point lays on $segment.
# @input {point} a point
# @param $segment {segment} line segment
# @output {boolean} true - if point lays on segment, false if not
#
# @see https://www.geeksforgeeks.org/how-to-check-if-a-given-point-lies-inside-a-polygon/
def is_on_segment($segment):
    . as $point
    | . as [ $x, $y ]
    | ( [ $segment[], $point ] | point::are_collinear ) as $colinear

    | $segment as [ [$x1, $y1], [$x2, $y2] ]

    | ( [ $x1, $x2 ] | sort ) as [ $minX, $maxX ]
    | ( [ $y1, $y2 ] | sort ) as [ $minY, $maxY ]

    | $colinear
      and $x >= $minX - EPSILON
      and $x <= $maxX + EPSILON
      and $y >= $minY - EPSILON
      and $y <= $maxY + EPSILON
;

##
# Tests if two segments intersect.
# @input {segment[2]} two line segments
# @output {boolean} true - if two segment intersect, false if not
# @see https://www.geeksforgeeks.org/how-to-check-if-a-given-point-lies-inside-a-polygon/
def do_segments_intersect:
    . as [ $seg1, $seg2 ]
    | . as [ [$p1, $q1], [$p2, $q2] ]

    | ( [$p1, $q1, $p2] | point::orientation ) as $o1
    | ( [$p1, $q1, $q2] | point::orientation ) as $o2
    | ( [$p2, $q2, $p1] | point::orientation ) as $o3
    | ( [$p2, $q2, $q1] | point::orientation ) as $o4

    | ($o1 != $o2 and $o3 != $o4)
      or
      ($o1 == 0 and ($p2 | is_on_segment($seg1)))
      or
      ($o2 == 0 and ($q2 | is_on_segment($seg1)))
      or
      ($o3 == 0 and ($q1 | is_on_segment($seg2)))
      or
      ($o4 == 0 and ($q1 | is_on_segment($seg2)))
;

##
# Calculates intersection point of two line segments.
# @input {segment[2]} two line segments
# @output {point | null} intersection point, or null if no intersection found
# @see http://www.cs.swan.ac.uk/~cssimon/line_intersection.html
def segment_intersection:
    . as [ [[$x1, $y1], [$x2, $y2]], [[$x3, $y3], [$x4, $y4]] ]

    | ( ($y3 - $y4)*($x1 - $x3) + ($x4 - $x3)*($y1 - $y3) ) as $na
    | ( ($x4 - $x3)*($y1 - $y2) - ($x1 - $x2)*($y4 - $y3) ) as $da
    | ( ($y1 - $y2)*($x1 - $x3) + ($x2 - $x1)*($y1 - $y3) ) as $nb
    | ( ($x4 - $x3)*($y1 - $y2) - ($x1 - $x2)*($y4 - $y3) ) as $db

    | if $da == 0 or $db == 0 then
          null
      else
          ( $na / $da ) as $ta
          | ( $nb / $db ) as $tb

          | if $ta >= 0
               and $ta <= 1
               and $tb >= 0
               and $tb <= 1 then
                ( $x1 + $ta*($x2 - $x1) ) as $x
                | ( $y1 + $ta*($y2 - $y1) ) as $y
                | [ $x, $y ]
            else
                null
            end
      end
;

##
# Transforms supplied line expressed in gradient-intercept form to line segment respecting $minX and
# $maxX.
# @input {[ number, number ]} line in gradient-intercept form
# @param $minX {number} min X
# @param $maxX {number} max X
# @output {segment} line segment
def line_to_segment($minX; $maxX):
    . as $line_by_x

    | ( $line_by_x | eval($minX) ) as $leftBorderY
    | ( $line_by_x | eval($maxX) ) as $rightBorderY

    | [ [$minX, $leftBorderY], [$maxX, $rightBorderY] ]
;

##
# Clips line segment inside the bounding box using Liang-Barsky algorithm. If input line segment is
# totally outside the box, methods output is empty.
# @input {segment} line segment to clip inside the box
# @param $boundaries {[ point, point ]} two points defining bounding box
# @output {segment} clipped line segment, or empty output if line segment lays outside the box
# @see http://www.skytopia.com/project/articles/compsci/clipping.html
def clip($boundaries):
    def approximate($round):
        if is_close_to($round) then
            $round
        else
            .
        end
    ;

    def stick($vals):
        reduce $vals[] as $val (.; approximate($val))
    ;

    ( .[0] | point::x ) as $x1
    | ( .[0] | point::y ) as $y1
    | ( .[1] | point::x ) as $x2
    | ( .[1] | point::y ) as $y2
    | ( $x2 - $x1 ) as $dX
    | ( $y2 - $y1 ) as $dY
    | ( $boundaries[0] | point::x ) as $minX
    | ( $boundaries[0] | point::y ) as $minY
    | ( $boundaries[1] | point::x ) as $maxX
    | ( $boundaries[1] | point::y ) as $maxY

    | ( -$dX ) as $p1
    | ( $dX ) as $p2
    | ( -$dY ) as $p3
    | ( $dY ) as $p4

    | ( $x1 - $minX ) as $q1
    | ( $maxX - $x1 ) as $q2
    | ( $y1 - $minY ) as $q3
    | ( $maxY - $y1 ) as $q4

    | if $x1 >= $minX and $x1 <= $maxX
         and $x2 >= $minX and $x2 <= $maxX
         and $y1 >= $minY and $y1 <= $maxY
         and $y2 >= $minY and $y2 <= $maxY then
          .     # segment is entirely within the box, no need clipping
      elif ($p1 == 0 and $q1 < 0) or ($p3 == 0 and $q3 < 0) then
          # Line segment is outside the box
          empty
      else
          # Make p/q pairs
          [ [$p1, $q1], [$p2, $q2], [$p3, $q3], [$p4, $q4] ]
          | map(select(.[0] != 0))

          | label $out
          | reduce .[] as [ $p, $q ] (
                [ 0, 1 ];   # pair t0/t1

                ( $q / $p ) as $r
                | . as [ $t0, $t1 ]

                | if $p < 0 then
                      if $r > $t1 then
                          null    # line outside the box
                          | break $out
                      elif $r > $t0 then
                          [ $r, $t1 ]
                      else
                          .
                      end
                  elif $p > 0 then
                      if $r < $t0 then
                          null    # line outside the box
                          | break $out
                      elif $r < $t1 then
                          [ $t0, $r ]
                      else
                          .
                      end
                  else
                      .   # impossible case
                  end
            )

          | if . != null then
                . as [ $t0, $t1 ]
                | [
                      [
                          ($x1 + $dX * $t0) | stick([ $minX, $maxX, $x1 ]),
                          ($y1 + $dY * $t0) | stick([ $minY, $maxY, $y1 ])
                      ],
                      [
                          ($x1 + $dX * $t1) | stick([ $minX, $maxX, $x2 ]),
                          ($y1 + $dY * $t1) | stick([ $minY, $maxY, $y2 ])
                      ]
                  ]
            else
                empty   # line outside the box
            end
      end
;
