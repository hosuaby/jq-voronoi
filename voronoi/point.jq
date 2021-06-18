module "point";

include "helpers";

##
# Cartesian point.
#
# type point = [ number, number ] | {
#     x: number,
#     y: number
# }
#
# @author hosuaby

##
# Returns x coordinate of supplied point.
# @input {point} point
# @output {number} x coordinate
def x:
    if type == "array" then
        .[0]
    else
        .x
    end
;

##
# Returns y coordinate of supplied point.
# @input {point} point
# @output {number} y coordinate
def y:
    if type == "array" then
        .[1]
    else
        .y
    end
;

##
# Checks that two points $a and $b are equal.
# @input {void} nothing
# @param $a {point} point 'a'
# @param $b {point} point 'b'
# @output {boolean} true if two points are equal, false if not
def equals($a; $b):
    ( $a | x ) as $ax
    | ( $a | y ) as $ay
    | ( $b | x ) as $bx
    | ( $b | y ) as $by
    | $ax == $bx and $ay == $by
;

##
# Tests if two points $a and $b are close one to another.
# @input {void} nothing
# @param $a {point} point 'a'
# @param $b {point} point 'b'
# @output {boolean} true if two points are very close, false if not
def are_close($a; $b):
    ( $a | x ) as $ax
    | ( $a | y ) as $ay
    | ( $b | x ) as $bx
    | ( $b | y ) as $by
    | ($ax | is_close_to($bx)) and ($ay | is_close_to($by))
;

##
# Calculates Euclidean distance between points $a and $b.
# @input {void} nothing
# @param $a {point} point 'a'
# @param $b {point} point 'b'
# @output {number} Euclidean distance between two points
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
# Finds orientation of three supplied points. Retuns:
#   -1 - points are counter-clockwise ordered
#    0 - points are collinear
#    1 - points are clockwise ordered
# @input {[ point, point, point ]} triplet of points
# @output {number} orientation of points
# @see http://www.geeksforgeeks.org/orientation-3-ordered-points/
def orientation:
    map(x) as [ $x1, $x2, $x3 ]
    | map(y) as [ $y1, $y2, $y3 ]
    | ($y2 - $y1) * ($x3 - $x2) - ($y3 - $y2) * ($x2 - $x1)
    | approximate(0)
    | sign
;

##
# Tests if tree supplied points are clockwise ordered.
# @input {[ point, point, point ]} triplet of points
# @output {boolean} true - if three points are clockwise ordered, false if not
def are_clockwise:
    orientation > 0
;

##
# Tests if tree supplied points are counter-clockwise ordered.
# @input {[ point, point, point ]} triplet of points
# @output {boolean} true - if three points are counter-clockwise ordered, false if not
def are_counterclockwise:
    orientation < 0
;

##
# Tests if tree supplied points are collinear ordered.
# @input {[ point, point, point ]} triplet of points
# @output {boolean} true - if three points are counter-clockwise ordered, false if not
def are_collinear:
    orientation == 0
;

##
# Compares two supplied points. Points are compared first by x, after if x coordinates are equal
# compared by y.
# @input {[point, point]} pair of points
# @output {number} negative integer - first point is strictly inferior, 0 - two points are equal,
#         positive integer - first point is strictly superior
def compare_by_x:
    . as [ $p1, $p2 ]
    | ( $p1 | x ) as $x1
    | ( $p1 | y ) as $y1
    | ( $p2 | x ) as $x2
    | ( $p2 | y ) as $y2

    | ( $x1 - $x2 ) as $Dx
    | if $Dx == 0 then
          $y1 - $y2
      else
          $Dx
      end
;

##
# Compares two supplied points. Points are compared first by y, after if y coordinates are equal
# compared by x.
# @input {[point, point]} pair of points
# @output {number} negative integer - first point is strictly inferior, 0 - two points are equal,
#         positive integer - first point is strictly superior
def compare_by_y:
    . as [ $p1, $p2 ]
    | ( $p1 | x ) as $x1
    | ( $p1 | y ) as $y1
    | ( $p2 | x ) as $x2
    | ( $p2 | y ) as $y2

    | ( $y1 - $y2 ) as $Dy
    | if $Dy == 0 then
          $x1 - $x2
      else
          $Dy
      end
;

##
# Calculates an angle between positive abscissa axe and supplied vector with respect to origin.
# @input {point} point
# @param $origin {point} origin
# @output {number} angle
def inclination($origin):
    . as [$x, $y]
    | ($x - $origin[0]) as $diffX
    | ($y - $origin[1]) as $diffY

    | atan2($diffY; $diffX)

    | if . < 0 then
          . + TWO_PI
      else
          .
      end
;

##
# Calculates an angle between positive abscissa axe and supplied vector.
# @input {point} vector
# @output {number} angle
def inclination:
    inclination([ 0, 0 ])
;
