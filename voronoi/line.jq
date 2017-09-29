module "line";

import "point" as point;

##
# Module for work with lines.
#
# type segment = [ point, point ];      // line segment
#
# @author hosuaby

##
# Clips line segment inside the bounding box using Liang-Barsky algorithm. If input line segment is
# totally outside the box, methods outputs nothing.
# @input {segment} line segment to clip inside the box
# @param $boundaries {[ point, point ]} two points defining bounding box
# @output {segment} clipped line segment, or empty output if line segment lays outside the box
# @see http://www.skytopia.com/project/articles/compsci/clipping.html
def clip($boundaries):
    ( .[0] | point::x ) as $x1
    | ( .[0] | point::y ) as $y1
    | ( .[1] | point::x ) as $x2
    | ( .[1] | point::y ) as $y2
    | ( $boundaries[0] | point::x ) as $minX
    | ( $boundaries[0] | point::y ) as $minY
    | ( $boundaries[1] | point::x ) as $maxX
    | ( $boundaries[1] | point::y ) as $maxY

    | ( $x1 - $x2 ) as $p1
    | ( -$p1 ) as $p2
    | ( $y1 - $y2 ) as $p3
    | ( -$p3 ) as $p4

    | ( $x1 - $minX ) as $q1
    | ( $maxX - $x1 ) as $q2
    | ( $y1 - $minY ) as $q3
    | ( $maxY - $y1 ) as $q4

    | if ($p1 == 0 and $q1 < 0) or ($p3 == 0 and $q3 < 0) then
          # Line segment is outside the box
          empty
      else
          # Make p/q pairs
          [ [$p1, $q1], [$p2, $q2], [$p3, $q3], [$p4, $q4] ]
          | reduce .[] as [ $p, $q ] (
                [ 0, 1 ];   # pair t0/t1

                ( $q / $p ) as $r

                | if . != null then
                      . as [ $t0, $t1 ]
                      | if $p < 0 then
                            if $r > $t1 then
                                null    # line outside the box
                            elif $r > $t0 then
                                [ $r, $t1 ]
                            else
                                .
                            end
                        elif $p > 0 then
                            if $r < $t0 then
                                null    # line outside the box
                            elif $r < $t1 then
                                [ $t0, $r ]
                            else
                                .
                            end
                        else
                            .   # impossible case
                        end
                  else
                      null   # nothing change, line is outside the box
                  end
            )

          | if . != null then
                . as [ $t0, $t1 ]
                | ( $x2 - $x1 ) as $dX
                | ( $y2 - $y1 ) as $dY
                | [
                      [ $x1 + $dX * $t0, $y1 + $dY * $t0 ],
                      [ $x1 + $dX * $t1, $y1 + $dY * $t1 ]
                  ]
            else
                empty   # line outside the box
            end
      end
;
