module "polygon";

include "helpers";

import "point" as point;
import "line" as line;
import "sphere" as sphere;

##
# Module for work with polygons in cartesian space.
#
# type polygon = point[];   // counter-clockwise ordered set of cartesian points
#
# @author hosuaby

##
# Returns counter-clockwise ordered set of polygon edges.
# @input {polygon} polygon
# @output {segment[]} polygon edges
def edges:
    [ .[], .[0] ]
    | bigrams
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
    | sort_by(point::inclination($p0))
    | collapse_by(point::inclination($p0); max_by(point::distance_euclidean($p0; .)))

    | reduce .[2:][] as $point ([ .[1], .[0], $p0 ];
        _while($point)
    )
;

##
# Tests if supplied point lays on the one of the edges of $polygon.
# @input {point} point in euclidean space
# @param $polygon {polygon} polygon
# @output {boolean} true - if point lays on polygon edge, false in not
def is_on_edge($polygon):
    . as $point

    | $polygon
    | edges
    | map(. as $edge | $point | line::is_on_segment($edge))
    | any
;

##
# Tests if supplied point lays inside or on the edge of provided $polygon.
# @input {point} point in euclidean space
# @param $polygon {polygon} polygon
# @output {boolean} true - point is inside or on the edge of polygon, false if not
def is_inside($polygon):
    . as $point

    | if is_on_edge($polygon) then
          true
      else
        $polygon
        | edges as $edges

        | [PLUS_INFINITY, $point[1]] as $extreme
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
# Tests if supplied line segment lays completely inside $polygon.
# @input {segment} line segment
# @param $polygon {polygon} polygon
# @output {boolean} true - if segment inside polygon, false if not
def is_segment_inside($polygon):
    map(is_inside($polygon))
    | all
;

##
# Tests if supplied polygon lays completely inside $outerPolygon.
# @input {polygon} this polygon
# @param $outerPolygon {polygon} outer polygon
# @output {boolean} true - if polygon is completely inside outer polygon, false if not
def is_polygon_inside($outerPolygon):
    map(is_inside($outerPolygon))
    | all
;

##
# Calculates intersections between line segment and convex polygon. Can find up to two
# intersections.
# @input {segment} line segment
# @param $polygon {polygon} polygon
# @output {point[:2]} intersections between line segment and polygon
def intersections_segment_polygon($polygon):
    . as $segment

    | $polygon
    | edges

    | map([$segment, .])
    | map(select(line::do_segments_intersect))
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
    | map(filter_empty)
;
