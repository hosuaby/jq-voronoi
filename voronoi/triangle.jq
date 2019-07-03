module "triangle";

##
# Module for work with triangles.
#
# type triangle = point[3]
#
# @author hosuaby

##
# Calculates centroid of triangle.
# @input {triangle} triangle
# @output {point} centroid of triangle
# @see https://brilliant.org/wiki/triangles-centroid/#finding-the-centroid
def centroid:
    . as [ [$x1, $y1], [$x2, $y2], [$x3, $y3] ]

    | ( ($x1 + $x2 + $x3) / 3 ) as $x
    | ( ($y1 + $y2 + $y3) / 3 ) as $y

    | [ $x, $y ]
;