module "polygon";

import "helpers" as helpers;
import "point" as point;
import "line" as line;
import "sphere" as sphere;

##
# Module for work with polygons in cartesian space.
#
# type polygon = point[];   // counter-clockwise ordered set of cartesian points
#
# @author hosuaby

# TODO: move into line package
def angle($center):
    . as [$x, $y]
    | ($x - $center.[0]) as $diffX
    | ($y - $center.[1]) as $diffY
    | atan2($diffY; $diffX)
    | if . < 0 then
          . + sphere::TWO_PI
      else
          .
      end
;

##
# Returns counter-clockwise ordered set of polygon edges.
# @input {polygon} polygon
# @output {segment[]} polygon edges
def edges:
    [ .[], .[0] ]
    | helpers::bigrams
;

##
# Constructs polygon from counter-clockwise ordered set of polygon edges.
# @input {segment[]} polygon edges
# @output {polygon} polygon
def from_edges:
    map(.[0])
;

##
# Computes the convex of Hull using Graham scan. Convex of Hull is a minimal bounding polygon that
# encloses all points from original set.
# @input {point[]} set of points in euclidean space
# @output {polygon} convex of Hull
#
# @see https://en.wikipedia.org/wiki/Graham_scan
def convex_hull:
    def _while($point):
        if length > 1 and ([.[1], .[0], $point ] | point::are_clockwise) then
            .[1:] | _while($point)
        else
            [ $point, .[] ]
        end
    ;

    min_by(point::y) as $p0

    | map(select(point::equals($p0; .) | not))
    | sort_by(angle($p0))
    | helpers::collapse_by(angle($p0); max_by(point::distance_euclidean($p0; .)))

    | reduce .[2:][] as $point ([ .[1], .[0], $p0 ];
        _while($point)
    )
;

def is_on_border($polygon):
    . as $point

    | $polygon
    | edges
    | map(. as $edge | $point | line::is_on_segment($edge))
    | any
;

##
# Tests if supplied point lays inside or on the edge of provided $polygon.
# @input {point} point if euclidean space
# @param $polygon {polygon} polygon
# @output {boolean} true - point is inside or on the edge of polygon, false if not
def is_inside($polygon):
    . as $point

    | if is_on_border($polygon) then
          true
      else
        $polygon
        | edges as $edges

        | [helpers::PLUS_INFINITY, $point[1]] as $extreme
        | [$point, $extreme] as $line
        | $edges
        | map([ ., $line ])

        | map(line::segment_intersection)
        | map(select(. !=  null))
        | length
        | . % 2 == 1
      end
;

##
# Calculates a biggest inner circle within supplied polygon with center in point $center.
# @input {polygon} polygon
# @param {point} euclidean point within polygon
# @output {circle} biggest euclidean circle within this polygon
def biggest_inner_circle($center):
    edges
    | map(
          if line::is_vertical then
              ( $center[0] - .[0][0] )
              | helpers::abs
          else
              line::to_gradient_intercept_form
              | line::dist_line_to_point($center)
          end
      )

    | { center: $center, radius: min }
;

##
# @input {segment}
def is_segment_inside($polygon):
    map(is_inside($polygon))
    | all
;

##
# @input {segment}
def is_segment_outside($polygon):
    map(is_inside($polygon) | not)
    | all
;

##
# @input {polygon} this polygon
def is_polygon_inside($outerPolygon):
    map(is_inside($outerPolygon))
    | all
;

##
# @input {segment}
def intersections_segment_polygon($polygon):
    . as $segment

    | $polygon
    | edges

    | map([$segment, .])
    | map(select(line::do_intersect))
    | map(
          . as $segments
          | line::segment_intersection
          | if . != null then
                .
            else
                $segments[0]
                | map(select(is_inside($polygon)))
                | .[0]
            end
      )
;

##
# @input {[ number, number ]} line in gradient-intercept form
def intersections_line_polygon($polygon):
    . as $line

    | $polygon
    | edges
    | map(. as $edge | $line | line::intersection_line_segment($edge))
;

##
# Splits convex polygon into up to two by provided line segment. If segment does not split polygon
# in two returns the same polygon wrapped into array.
# @input {polygon} polygon
# @param $segment {segment} segment cutting polygon
# @output {polygon[1:2]} one or two polygons
def split($segment):
    edges
    | reduce .[] as $edge (
          {
              this: [],
              other: [],
              intersections: []
          };

          . as $state
          | [ $edge, $segment ]
          | line::segment_intersection as $intersection

          | $state
          | if $intersection == null then
                {
                    this: [ .this[], $edge ],
                    other,
                    intersections
                }
            else
                {
                    this,
                    other,
                    intersections: [ .intersections[], $intersection ]
                }

                | if (.intersections | length) == 1 then
                      {
                          this: [ .this[], [ $edge[0], $intersection ] ],
                          other: [ .other[], [ $intersection, $edge[1] ] ],
                          intersections
                      }
                  else
                      # Second intersection
                      {
                          this: [
                              .this[],
                              [ $edge[0], $intersection ],
                              (.intersections | reverse)
                          ],
                          other: [
                              .other[],
                              .intersections,
                              [ $intersection, $edge[1]]
                          ],
                          intersections
                      }
                  end

                | { this: .other, other: .this, intersections }
            end
      )

    | [ .this, .other ]

    | map(from_edges)
    | map(helpers::filter_empty)
;

def subtract($other):
    . as $this

    | edges
    | map(
          if is_segment_outside($other) then
              .
          elif is_polygon_inside($other) then
              empty
          else
              . as $edge
              | intersections_segment_polygon($other)
              | .[0]
              | if $edge[0] | is_inside($other) then
                    # First point inside
                    [ ., $edge[1] ]
                else
                    # Second point inside
                    [ $edge[0], . ]
                end
          end
      )

    | flatten(1)
;
