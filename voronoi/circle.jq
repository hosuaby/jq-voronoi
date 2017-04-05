module "circle";

import "point" as point;

##
# Circle.
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
# @input [ point, point, point ] triplet of non-collinear points
# @output point center of circle
def circle_center:
    . as [ $p1, $p2, $p3 ]
    | ( $p1 | point::x ) as $x1
    | ( $p1 | point::y ) as $y1
    | ( $p2 | point::x ) as $x2
    | ( $p2 | point::y ) as $y2
    | ( $p3 | point::x ) as $x3
    | ( $p3 | point::y ) as $y3

    # Calculate slopes
    | ( [ $p1, $p2 ] | point::slope ) as $ma
    | ( [ $p2, $p3 ] | point::slope ) as $mb

    | ( ( $ma * $mb * ($y1 - $y3) + $mb * ($x1 + $x2) - $ma * ($x2 + $x3) )
        / ( 2 * ($mb - $ma) ) ) as $x

    | ( -1/$ma * ($x - ($x1 + $x2)/2) + ($y1 + $y2)/2 ) as $y

    | [ $x, $y ]
;

##
# Creates the circle that passes through supplied 3 points.
# Precondition: three points must not be collinear.
# @input [ point, point, point ] triplet of non-collinear points
# @output circle
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
# @input circle
# @output point the lowest point
def bottom:
    [
        (.center | point::x),
        (.center | point::y) + .radius
    ]
;
