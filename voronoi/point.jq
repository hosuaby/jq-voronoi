module "point";

##
# Cartesian point.
# type point = [ number, number ] | {
#     x: number,
#     y: number
# }
#
# @author hosuaby

##
# Returns x coordinate of supplied point.
# @input point object
# @output x coordinate
def x:
    if type == "array" then
        .[0]
    else
        .x
    end
;

##
# Returns y coordinate of supplied point.
# @input point object
# @output y coordinate
def y:
    if type == "array" then
        .[1]
    else
        .y
    end
;

##
# Checks that two points $a and $b are equal.
# @input nothing
# @param $a tuple of coordinates of point 'a'
# @param $b tuple of coordinates of point 'b'
# @output true if two points are equal, false if not
def equals($a; $b):
    ( $a | x ) as $ax
    | ( $a | y ) as $ay
    | ( $b | x ) as $bx
    | ( $b | y ) as $by
    | $ax == $bx and $ay == $by
;

def close($a; $b):
    ( $a | x ) as $ax
    | ( $a | y ) as $ay
    | ( $b | x ) as $bx
    | ( $b | y ) as $by
    | ( $bx - $ax ) as $dX
    | ( $by - $ay ) as $dY
    | pow($dX; 2) < 0.005 and pow($dY; 2) < 0.005
;

##
# Calculates Euclidean distance between points $a and $b.
# @input nothing
# @param $a tuple of coordinates of point 'a'
# @param $b tuple of coordinates of point 'b'
# @output Euclidean distance between two points
def distance_euclidean($a; $b):
    ( $a | x ) as $ax
    | ( $a | y ) as $ay
    | ( $b | x ) as $bx
    | ( $b | y ) as $by
    | pow(
        pow(($ax - $bx); 2)
        +
        pow(($ay - $by); 2);
        0.5
    )
;

##
# Calculates angle of the line formed by points $a and $b. The order of the points matter. Point $a is considered as
# 'start' of the line and point $b as its end.
# @input nothing
# @param $a tuple of coordinates of point 'a'
# @param $b tuple of coordinates of point 'b'
# @output angle of the line between two points
def angle($a; $b):
    ( $a | x ) as $ax
    | ( $a | y ) as $ay
    | ( $b | x ) as $bx
    | ( $b | y ) as $by
    | atan2($by - $ay; $bx - $ax)
;

##
# Tests if tree supplied points are collinear.
# @input {[ point, point, point ]} triplet of points
# @output {boolean} true - if three points are collinear, false if not
# @see http://www.geeksforgeeks.org/orientation-3-ordered-points/
def are_collinear:
    map(x) as [ $x1, $x2, $x3 ]
    | map(y) as [ $y1, $y2, $y3 ]

    # Points are collinear if:
    #   (y2 - y1)*(x3 - x2) - (y3 - y2)*(x2 - x1) = 0
    | ($y2 - $y1) * ($x3 - $x2) - ($y3 - $y2) * ($x2 - $x1) == 0
;

##
# Tests if tree supplied points are counter-clockwise ordered.
# @input {[ point, point, point ]} triplet of points
# @output {boolean} true - if three points are counter-clockwise ordered, false if not
# @see http://www.geeksforgeeks.org/orientation-3-ordered-points/
def are_counterclockwise:
    map(x) as [ $x1, $x2, $x3 ]
    | map(y) as [ $y1, $y2, $y3 ]

    # Points are counter-clockwise ordered if:
    #   (y2 - y1)*(x3 - x2) - (y3 - y2)*(x2 - x1) < 0
    | ($y2 - $y1) * ($x3 - $x2) - ($y3 - $y2) * ($x2 - $x1) < 0
;

##
# Calculates slope of line segment formed by supplied pair of points.
# @input {[ point, point ]} pair of points
# @output {number} slope of line segment
def slope:
    ( .[0] | x ) as $x1
    | ( .[0] | y ) as $y1
    | ( .[1] | x ) as $x2
    | ( .[1] | y ) as $y2

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
    | ( .[0] | x ) as $x1
    | ( .[0] | y ) as $y1

    # b = y - mx
    | ( $y1 - $slope * $x1 ) as $intercept

    | [ $slope, $intercept ]
;

##
# Calculates equation of perpendicular line of the line expressed in gradient-intercept form.
# @input {[ number, number ]} line in gradient-intercept form
# @param {point} point through which perpendicular pass
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

    # b = y + mx
    | ( $point | x ) as $x
    | ( $point | y ) as $y
    | ( $y + $slope * $x ) as $intercept

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
# Evaluates gradient-intercept line equation for supplied input.
# Function accepts two forms of line:
#   1) y = mx + b
#   2) x = my + c
# @input {[ number, number ]} line in gradient-intercept form
# @param $val {number} value for which equation must be evaluated
# @output {number} result of evaluation of equation
# TODO: rename to eval
def eval_line($val):
    . as [ $slope, $intercept ]
    | $slope * $val + $intercept
;

##
# Calculates midpoint of a line segment.
# @input {[ point, point ]} pair of points defining line segment
# @output {point} midpoint of the line segment
# @see http://www.purplemath.com/modules/midpoint.htm
def midpoint:
    [
        ( (.[0] | x) + (.[1] | x) ) / 2,
        ( (.[0] | y) + (.[1] | y) ) / 2
    ]
;
