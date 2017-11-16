module "line";

import "helpers" as helpers;
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
# @input {[ point, point ]} pair of points
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
# Clips line segment inside the bounding box using Liang-Barsky algorithm. If input line segment is
# totally outside the box, methods output is empty.
# @input {segment} line segment to clip inside the box
# @param $boundaries {[ point, point ]} two points defining bounding box
# @output {segment} clipped line segment, or empty output if line segment lays outside the box
# @see http://www.skytopia.com/project/articles/compsci/clipping.html
def clip($boundaries):
    def approximate($round):
        if helpers::is_close_to($round) then
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
