module "sphere";

include "helpers";

import "linear_algebra" as la;

##
# Module for work with sphere.
#
# type sphericalPoint = [
#     number,   # 0 <= azimuth < 2PI
#     number    # 0 <= zenith <= PI
# ]
#
# type 3dCartesianPoint = number[3]     # x, y, z
#
# type polarPoint = [
#      number,      # distance
#      number       # 0 <= angle <= 2PI
# ]
#
# @author hosuaby

def UNIT_SPHERE_AREA: PI * 4;

##
# Projects using stereographic projection point expressed in spherical coordinates on unit sphere to
# point on the plane expressed in radial coordinates using north pole (0, 0) as projection point.
# @input {sphericalPoint} point in spherical coordinates
# @output {polarPoint} projection in polar points
def spherical_to_polar:
    . as [ $azimuth, $zenith ]
    | $azimuth as $angle
    | ( ((PI - $zenith) / 2) | tan ) as $distance
    | [ $distance, $angle ]
;

##
# Projects point expressed in polar coordinates on the sphere with diameter equal to 1 using the
# north pole (0, 0) as projection point.
# @input {polarPoint} point in polar coordinates
# @output {sphericalPoint} projection on the sphere
def polar_to_spherical:
    . as [ $distance, $angle ]
    | $angle as $azimuth
    | ( PI - ($distance | atan) * 2 ) as $zenith
    | [ $azimuth, $zenith ]
;

##
# Transforms point expressed in polar coordinates into cartesian coordinates.
# @input {polarPoint} point in polar coordinates
# @param $scale {number} scaling factor
# @output {point} point in cartesian coordinates
def polar_to_cartesian($scale):
    . as [ $distance, $angle ]
    | ( $distance * $scale * ($angle | cos) ) as $x
    | ( $distance * $scale * ($angle | sin) ) as $y
    | [ $x, $y ]
;

##
# Transforms point expressed in cartesian coordinates into polar coordinates.
# @input {point} point in cartesian coordinates
# @param $scale {number} scaling factor
# @output {polarPoint} point in polar coordinates
def cartesian_to_polar($scale):
    . as [ $x, $y ]
    | ( (($x * $x + $y * $y) | sqrt) / $scale ) as $distance
    | atan2($y; $x) as $angle
    | [ $distance, $angle ]
;

##
# Calculates distance between input point and parameter point expressed in polar coordinates.
# @input {polarPoint} destination point in polar coordinates
# @param $origin {polarPoint} origin point in polar coordinates
# @output {number} distance between two points
# @see https://www.ck12.org/book/CK-12-Trigonometry-Concepts/section/6.2/
def polar_distance_from($origin):
    . as [ $destR, $destTheta ]
    | $origin as [ $origR, $origTheta ]

    | pow($origR; 2)
      +
      pow($destR; 2)
      -
      2 * $origR * $destR * ( $destTheta - $origTheta | cos )
    | sqrt
;

##
# Tests if supplied point is the north pole of the sphere.
# @input {sphericalPoint} point in spherical coordinates
# @output {boolean} true if point is the north pole, false if not
def is_spherical_north_pole:
    .[1] < EPSILON
;

##
# Tests if supplied point is the south pole of the sphere.
# @input {sphericalPoint} point in spherical coordinates
# @output {boolean} true if point is the south pole, false if not
def is_spherical_south_pole:
    ( PI - .[1] )
    | abs
    | . < EPSILON
;

##
# Calculates haversine of angle.
# @input {number} angle in radians
# @output {number} haversine
# @see https://en.wikipedia.org/wiki/Haversine_formula
def haversine:
    . / 2
    | sin
    | pow(.; 2)
;

##
# Calculates spherical distance between input point and parameter point on sphere  with diameter
# 1 unit.
# @input {sphericalPoint} destination point in spherical coordinates
# @param $origin {sphericalPoint} origin point in spherical coordinates
# @output {number} distance between two points
# @see https://en.wikipedia.org/wiki/Haversine_formula
def spherical_distance_from($origin):
    is_spherical_north_pole as $northPole
    | is_spherical_south_pole as $southPole

    | . as [ $destAzimuth, $destZenith ]
    | $origin as [ $origAzimuth, $origZenith ]

    | if ($northPole and ($origin | is_spherical_north_pole)) then
          0
      elif ($southPole and ($origin | is_spherical_south_pole)) then
          0
      else
          ($destAzimuth - $origAzimuth) as $deltaAzimuth
          | ($destZenith - $origZenith) as $deltaZenith

          | ($deltaZenith | haversine)
            +
            (($origZenith - HALF_PI) | cos) * (($destZenith - HALF_PI) | cos) * ($deltaAzimuth | haversine)
          | sqrt
          | asin
          | . * 2
      end
;

##
# Calculates spherical excess of triangle.
# @input {sphericalPoint[3]} triangle of spherical surface
# @output {number} spherical excess of triangle
# @see https://codegolf.stackexchange.com/questions/63870/spherical-excess-of-a-triangle
def excess:
    def _approximate:
        approximate(-1)
        | approximate(1)
    ;

    . as [ $p1, $p2, $p3 ]

    | $p1
    | spherical_distance_from($p2) as $a

    | $p1
    | spherical_distance_from($p3) as $b

    | $p2
    | spherical_distance_from($p3) as $c

    | ($a | cos) - ($b | cos) * ($c | cos)
    | . / ( ($b | sin) * ($c | sin) )
    | _approximate
    | acos as $A

    | ($b | cos) - ($c | cos) * ($a | cos)
    | . / ( ($c | sin) * ($a | sin) )
    | _approximate
    | acos as $B

    | ($c | cos) - ($a | cos) * ($b | cos)
    | . / ( ($a | sin) * ($b | sin) )
    | _approximate
    | acos as $C

    | $A + $B + $C - PI
;

##
# Tests if three points on spherical surface are collinear. We can assert it using spherical excess
# of triangle formed by those points. If points are collinear, excess is 0.
# @input {sphericalPoint[3]} triangle of spherical surface
# @output {boolean} true - if three points are collinear, false if not
def are_collinear:
    excess
    | is_close_to(0)
;

##
# Flips supplied point following vertical axis. The site that was in north hemisphere passes to
# south hemisphere.
# @input {sphericalPoint} point in spherical coordinates
# @output {sphericalPoint} flipped point
def spherical_flip:
    [ .[0], PI - .[1] ]
;

##
# Normalizes the input point. Brings its azimuth to range between 0 and TWO_PI and its zenith
# between 0 and PI.
# @input {sphericalPoint} point in spherical coordinates
# @output {sphericalPoint} the same point with normalized coordinates
def normalize:
    . as [ $azimuth, $zenith ]
    | (
        if $azimuth < 0 then
            $azimuth + TWO_PI
        elif $azimuth >= TWO_PI then
            $azimuth - TWO_PI
        else
            $azimuth
        end
      ) as $azimuth

    | (
        if $zenith < 0 then
            -$zenith
        elif $zenith > PI then
            $zenith - PI
        else
            $zenith
        end
      ) as $zenith

    | [ $azimuth, $zenith ]
;

##
# Projects point on spherical surface on the plane using north pole [0, 0] as projection point.
# @input {sphericalPoint} point in spherical coordinates
# @output {point} point in cartesian coordinates
def spherical_to_cartesian:
    spherical_to_polar | polar_to_cartesian(1)
;

##
# Projects point from the plane on sphere surface using north pole [0, 0] as projection point.
# @input {point} point in cartesian coordinates
# @output {sphericalPoint} point in spherical coordinates
def cartesian_to_spherical:
    cartesian_to_polar(1) | polar_to_spherical
;

##
# Projects circle from plane (center in polar coordinates) to sphere surface.
# @input {circle} circle with center expressed in polar coordinates.
# @output {circle} circle on spherical surface. Center is point in spherical coordinates, and radius
#                  is distance on sphere along the great circle
def circle_to_sphere:
    def to_sphere_zenith:
        [., 0]
        | polar_to_spherical
        | .[1]
    ;

    .center as [ $distance, $angle ]
    | .radius as $radius

    | ( $distance - $radius | to_sphere_zenith ) as $top
    | ( $distance + $radius | to_sphere_zenith ) as $bottom

    | ( ($top - $bottom) / 2 ) as $r
    | ( $top - $r ) as $zenith

    | {
          center: [ $angle, $zenith ],
          radius: $r
      }
;

##
# Project circle from sphere to plane. Center of output circle expressed in polar coordinates.
# @input {circle} circle of sphere surface
# @output {circle} circle on plane. Center is expressed in polar coordinates.
def circle_to_plane:
    def to_polar_distance:
        [0, .]
        | spherical_to_polar
        | .[0]
    ;

    .center as [ $azimuth, $zenith ]
    | .radius as $radius

    | ( $zenith - $radius | to_polar_distance ) as $top
    | ( $zenith + $radius | to_polar_distance ) as $bottom

    | ( ($top - $bottom) / 2 ) as $r
    | ( $top - $r ) as $distance

    | {
          center: [ $distance, $azimuth ],
          radius: $r
      }
;

##
# Calculates minimum zenith coordinate of site on sphere surface that can be safely (according
# 64-bit floating point arithmetic) be projected on the plane.
# @input {void} nothing
# @output {number} minimum zenith coordinate of site on sphere
def find_minimum_zenith:
    def delta:
        . as $original
        | [0, .]
        | spherical_to_cartesian
        | cartesian_to_spherical
        | .[1]
        | $original - .
        | abs
    ;

    [ 0, PI ]

    | until((.[1] - .[0]) <= EPSILON;
          ( (.[0] + .[1]) / 2 ) as $mid

          | ( $mid | delta ) as $delta

          | if ($delta < EPSILON) then
                [ .[0], $mid ]
            else
                [ $mid, .[1] ]
            end
      )

    | .[1]
;

##
# Converts spherical coordinates to 3D cartesian coordinates.
# @input {sphericalPoint} point in spherical coordinates
# @output {3dCartesianPoint} point in cartesian coordinates
# @see https://math.stackexchange.com/a/1404353
def to_3d_cartesian:
    . as [ $azimuth, $zenith ]
    | [
          ($zenith | sin) * ($azimuth | cos),
          ($zenith | sin) * ($azimuth | sin),
          ($zenith | cos)
      ]
;

##
# Converts 3D cartesian coordinates to spherical coordinates.
# @input {3dCartesianPoint} point in cartesian coordinates
# @output {sphericalPoint} point in spherical coordinates
# @see https://math.stackexchange.com/a/1404353
def from_3d_cartesian:
    . as [ $x, $y, $z ]

    | atan2($y; $x) as $azimuth
    | atan2(
          ($x*$x + $y*$y) | sqrt;
          $z
      ) as $zenith

    | [ $azimuth, $zenith ]
    | normalize
;

##
# Calculates cross-product of two points on spherical surface expressed in cartesian coordinates.
# @input {3dCartesianPoint[2]} two vectors in 3D cartesian space
# @output {3dCartesianPoint} cross-product of two vectors
# @see https://www.analyzemath.com/stepbystep_mathworksheets/vectors/cross_product.html
def cross_product:
    . as [ [$x1, $y1, $z1], [$x2, $y2, $z2] ]

    | [ [$y1, $y2], [$z1, $z2] ]
    | la::determinant as $x

    | [ [$x1, $x2], [$z1, $z2] ]
    | la::determinant
    | (-.) as $y

    | [ [$x1, $x2], [$y1, $y2] ]
    | la::determinant as $z

    | [ $x, $y, $z ]
;

##
# Calculates cross-product matrix used to find Rodrigues' rotation matrix K.
# @input {3dCartesianPoint} rotation axe in cartesian coordinates
# @output {matrix} cross-product matrix
# @see https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula#Matrix_notation
def cross_product_matrix:
    . as [ $kx, $ky, $kz ]
    | [
          [ 0, $kz, -$ky ],
          [ -$kz, 0, $kx ],
          [ $ky, -$kx, 0 ]
      ]
;

##
# Calculates Rodrigues' rotation matrix R.
# @input {matrix} cross-product matrix K
# @param $theta {number} rotation angle
# @output {matrix} rotation matrix
# @see https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula#Matrix_notation
def rotation_matrix($theta):
    . as $K
    | la::multiply_with_scalar($theta | sin) as $A
    | la::multiply_with_matrix($K)
    | la::multiply_with_scalar(1 - ($theta | cos)) as $B
    | la::identity(3)
    | la::add_matrix($A)
    | la::add_matrix($B)
;

##
# Rotates a vector in 3D euclidean space using Rodrigue's rotation matrix.
# @input {3dCartesianPoint} vector
# @param $R {matrix} rotation matrix
# @output {3dCartesianPoint} rotated vector
# @see https://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula#Matrix_notation
def rotate($R):
    [.] as $vector
    | $R
    | la::multiply_with_matrix($vector)
    | .[0]
;

##
# Calculates centroid of triangle of sphere surface.
# @input {sphericalPoint[3]} triangle on spherical surface.
# @output {sphericalPoint} centroid of triangle
# @see https://math.stackexchange.com/a/2333674
def centroid:
    map(to_3d_cartesian)
    | map([.])
    | . as [ $A, $B, $C ]

    | $A
    | la::add_matrix($B)
    | la::add_matrix($C) as $cp

    | $cp
    | la::norm as $n

    | $cp
    | la::multiply_with_scalar(1 / $n)
    | .[0]

    | from_3d_cartesian
;

##
# Returns rectangle on sphere surface delimiting the zone that can be projected from north pole. The
# points that are too close to north pole can not projected because the distance of projection in
# polar coordinates will be too high to be precisely represented by 64-bits floating point number.
def projection_limit:
    find_minimum_zenith as $minZenith
    | [
          [ 5 * PI / 4, $minZenith ],
          [ PI / 4, $minZenith ]
      ]
;
