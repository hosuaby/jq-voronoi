module "parabola";

import "point" as point;

##
# type parabola = {
#     focus: point,         // focus point of parabola
#     directrix: number     // y coordinate of directrix line (swipe line)
# }
#
# @see http://en.wikipedia.org/wiki/Parabola
# @see http://en.wikipedia.org/wiki/Quadratic_equation
#
# @author hosuaby

##
# Translates parabola json object into standard form for parabola symmetrical by y-axis:
#       a(x-h)²+k
# where
#       a - coefficient of how "skinny" parabola is
#       [ h, k ] - vertex of parabola
# @input parabola json object
# @return triplet of [a, h, k]
# @see https://www.physicsforums.com/threads/parabolas-canonical-form-help-please.548439
def to_standard_form:
    ( .focus | point::x ) as $fx
    | ( .focus | point::y ) as $fy
    | ( $fy - .directrix ) as $fl
    | if $fl < 0 then
          [
              1 / ( $fl * 2 ),
              $fx,
              $fy - $fl / 2
          ]
      else
          error("Focus length of parabola is \($fl)")
      end
;

##
# Evaluates function y = a(x-h)²+k for x supplied as input.
# @param $func triplet of [ a, h, k ]
# @input x
# @output evaluated y
def eval($func):
    . as $x
    | $func as [ $a, $h, $k ]

    | $a * pow(( $x - $h ); 2) + $k
;

##
# Finds points (zero, one or two) of intersection between two parabolas given in their standard
# form.
# Assuming:
#       p1 = a1(x-h1)²+k1
#       p2 = a2(x-h2)²+k2
# their intersections can be found as:
#       p1 = p2
#       a1(x-h1)²+k1 = a2(x-h2)²+k2
#           => ...
#       x²(a1-a2) + x*2(a2h2-a1h1) + (a1h1²-a2h2²+k1-k2) = 0
# so we have to resolve quadratic equation:
#       ax² + bx + c = 0
# where
#       a = a1 - a2
#       b = 2 * (a2h2 - a1h1)
#       c = a1h1² - a2h2² + k1 - k2
# @input nothing
# @param $p1 first parabola in standard form
# @param $p2 second parabola in standard form
# @output point[0:2] array of zero, one or two points of intersection between parabolas. If there
# are two points of
# @see https://conceptdraw.com/a232c3/preview
def intersections($p1; $p2):
    $p1 as [ $a1, $h1, $k1 ]
    | $p2 as [ $a2, $h2, $k2 ]

    | ( $a1 - $a2 ) as $a
    | ( 2 * ($a2*$h2 - $a1*$h1) ) as $b
    | ( $a1*pow($h1;2) - $a2*pow($h2;2) + $k1 - $k2 ) as $c

    | if $a == 0 then
        if $b == 0 then
            []  # no solution
        else
            # One solution
            ( -$c / $b ) as $x
            | ( $x | eval($p1) ) as $y
            | [ [ $x, $y ] ]
        end
      else
        ( pow($b;2) - 4 * $a * $c ) as $D
        | if $D < 0 then
            []  # no solution
          elif $D == 0 then
            # One solution
            ( -$b / 2 * $a ) as $x
            | ( $x | eval($p1) ) as $y
            | [ $x, $y ]
          else
            # Two solutions
            ( (-$b-pow($D;0.5)) / (2*$a) ) as $x1
            | ( (-$b+pow($D;0.5)) / (2*$a) ) as $x2
            | ( $x1 | eval($p1) ) as $y1
            | ( $x2 | eval($p1) ) as $y2
            | [ [$x1, $y1], [$x2, $y2] ]
            | sort_by(.[0])     # returned intersection points are ordered by x
          end
      end
;
