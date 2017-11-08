module "circle";

import "point" as point;

##
# Module for work with circles.
#
# type circle = {
#     center: point,
#     radius: number
# }
#
# @author hosuaby
# @see http://paulbourke.net/geometry/circlesphere/

##
# Calculates the center of circle that pass through supplied 3 points.
# Precondition: three points must not be collinear.
# @input {[ point, point, point ]} triplet of non-collinear points
# @output {point} center of circle
# @see http://www.ambrsoft.com/TrigoCalc/Circle3D.htm
def circle_center:
    . as [ $p1, $p2, $p3 ]
    | ( $p1 | point::x ) as $x1
    | ( $p1 | point::y ) as $y1
    | ( $p2 | point::x ) as $x2
    | ( $p2 | point::y ) as $y2
    | ( $p3 | point::x ) as $x3
    | ( $p3 | point::y ) as $y3

    | ( pow($x1;2) + pow($y1;2) ) as $q1
    | ( pow($x2;2) + pow($y2;2) ) as $q2
    | ( pow($x3;2) + pow($y3;2) ) as $q3

    | ( $x1*($y2-$y3) - $y1*($x2-$x3) + $x2*$y3 - $x3*$y2 ) as $A

    | ( $q1 * ($y3-$y2)
        +
        $q2 * ($y1-$y3)
        +
        $q3 * ($y2-$y1) ) as $B

    | ( $q1 * ($x2-$x3)
        +
        $q2 * ($x3-$x1)
        +
        $q3 * ($x1-$x2) ) as $C

    | ( $q1 * ($x3*$y2-$x2*$y3)
        +
        $q2 * ($x1*$y3-$x3*$y1)
        +
        $q3 * ($x2*$y1-$x1*$y2) ) as $D

    | ( -$B / (2*$A) ) as $x
    | ( -$C / (2*$A) ) as $y

    | [ $x, $y ]
;

##
# Creates the circle that passes through supplied 3 points.
# Precondition: three points must not be collinear.
# @input {[ point, point, point ]} triplet of non-collinear points
# @output {circle} circle
def from_triplet:
    circle_center as $center
    | point::distance_euclidean(.[0]; $center) as $radius
    | {
        center: $center,
        radius: $radius
    }
;

##
# Calculates bottom (the lowest point) of the circle.
# @input {circle} circle
# @output {point} the lowest point of the circle
def bottom:
    [
        (.center | point::x),
        (.center | point::y) + .radius
    ]
;
