module "voronoi_basin";

import "point" as point;
import "line" as line;
import "rectangle" as rectangle;
import "circle" as circle;
import "polygon" as polygon;

##
# Module for local calculation of Voronoi diagrams.
# Implementation of whitepaper "Local calculation of Voronoi diagrams" by Ulrich Kühn.
#
# type voronoi_basin = site[]
#
# @see https://www.sciencedirect.com/science/article/pii/S002001909800180X
# @author hosuaby

##
# Calculates Voronoi basin of bounding $polygon.
# Precondition: bonding polygon must have at least one site inside
# @input {site[]} array of all sites
# @param $polygon {polygon} bounding polygon
# @param $anchor {site} anchor site
# @output {voronoi_basin} voronoi bassin
def voronoi_basin($polygon; $anchor):
    . as $sites

    | $polygon
    | map(
          point::distance_euclidean(.; $anchor) as $radius
          | { "center": ., "radius": $radius }
      ) as $basin

    | $sites
    | map(select(
          . as $site
          | $basin
          | any(. as $circle | $site | circle::is_inside($circle))
      ))
;

##
# Calculates the bounding region (voronoi cell) of the $site with respect to other sites.
# Method returns a polygon, not a whole voronoi cell. The last must include the site itself.
# @input {site[]} other sites
# @param $site {site} anchor site
# @param $box {rectangle} bounding box
# @output {polygon} bounding region
def voronoi_region($site; $box):
    . as $other_sites
    | $box as [ [$minX, $minY], [$maxX, $maxY] ]
    | $box
    | rectangle::to_polygon as $polygon

    | reduce $other_sites[] as $other_site (
          $polygon;

          . as $result
          | [ $site, $other_site ]

          | line::midpoint as $midpoint

          | if line::is_vertical then
                # Cutting segment is horizontal
                [ [$minX, $midpoint[1]], [$maxX, $midpoint[1]] ]
            elif line::is_horizontal then
                # Cutting segment is vertical
                [ [$midpoint[0], $minY], [$midpoint[0], $maxY] ]
            else
                line::to_gradient_intercept_form
                | line::perpendicular($midpoint)
                | line::line_to_segment($minX; $maxX)
            end

          | . as $splitting_segment

          | $result
          | polygon::split($splitting_segment)
          | map(select(. as $p | $site | polygon::is_inside($p)))
          | .[0]
      )
;
