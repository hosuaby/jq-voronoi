module "spherical_voronoi";

import "helpers" as helpers;
import "point" as point;
import "circle" as circle;
import "rectangle" as rectangle;
import "polygon" as polygon;
import "sphere" as sphere;
import "fortune" as fortune;
import "voronoi_basin" as vb;

##
# Module for calculation of voronoi diagrams of sphere.
# Implementation of whitepaper "Voronoi diagrams on the sphere" by Hyeon-Suk Na, Chung-Nim Lee
# & Otfried Cheong.
#
# @see https://www.sciencedirect.com/science/article/pii/S0925772102000779?via%3Dihub
# @author hosuaby

##
# Tests if supplied cell lays completely inside $box.
# @input {cell} voronoi cell on the plane
# @param $box {rectangle} bounding box
# @output {boolean} true if cell lays completely inside box, false in not.
def is_cell_inside_box($box):
    map(rectangle::is_inside($box))
    | all
;

def is_bound_cell($box):
    . as $cell
    | map(rectangle::is_inside($box))
    | all
;

##
# Removes all vertexes of voronoi cell that situates on the border of the bounding box. Returns
# cell with trigonometrically ordered remaining vertexes.
# @input {cell} planar voronoi cell
# @param $box {rectangle} bounding box
# @output {cell} planar voronoir cell without vertexes on border
def remove_vertexes_on_border($box):
    .[0] as $site
    | .[1:]
    | helpers::count(rectangle::is_inside($box)) as $nbInside
    | until(.[:$nbInside] | all(rectangle::is_inside($box)); helpers::rotate_left)
    | .[:$nbInside]
    | [ $site, .[] ]
;

def merge_two_cells:
    . as [ $cell1, $cell2 ]
    | $cell1[0] as $site

    | [ $cell1[1:][], $cell2[1:][] ]

    | [ $site, .[] ]
;

##
# Projects vertex of voronoi cell from plane to sphere. Uses formula for projection of circle as
# vertex of voronoi cell is a center of circle between three or more sites.
# @input {polarPoint} vertex in polar coordinates
# @param $site {polarPoint} cells site in polar coordinates
# @output {sphericalPoint} projection of cell vertex on shpere surface
def project_vertex($site):
    { center: ., radius: sphere::polar_distance_from($site) }
    | sphere::circle_to_sphere
    | .center
;

##
# Projects voronoi cell from plane to sphere surface.
# @input {cell} voronoi cell on the plane
# @output {cell} voronoi cell on the sphere
def project_cell:
    map(sphere::cartesian_to_polar(1))
    | .[0] as $site
    | .[1:]
    | map(project_vertex($site))

    | [
          ( $site | sphere::polar_to_spherical ),
          .[]
      ]
;

def project_unbound_cell($box):
    ( .[0] | sphere::cartesian_to_polar(1) ) as $site

    | .[1:]
    | map(
          if rectangle::is_inside($box) then
              sphere::cartesian_to_polar(1)
              | project_vertex($site)
          else
              sphere::cartesian_to_spherical
          end
      )

    | [
          ( $site | sphere::polar_to_spherical ),
          .[]
      ]
;

def project_cell_to_plane:
    .[0] as $site
    | .[1:]
    | map({ center: ., radius: sphere::spherical_distance_from($site) })
    | map(sphere::circle_to_plane)
    | map(.center)
    | map(sphere::polar_to_cartesian(1))
    | [
          ( $site | sphere::spherical_to_cartesian ),
          .[]
      ]
;

def polar_cell:
    map(sphere::spherical_flip)
    | map(sphere::spherical_to_cartesian) as $sites

    | sphere::projection_limit
    | map(sphere::spherical_to_cartesian) as $box

    | $sites
    | vb::voronoi_region([0, 0]; $box)

    | [ [0, 0], .[] ]
    | project_cell

    | map(sphere::spherical_flip)
;

##
# @input {sphericalPoint} non north pole sites
# @output {sphericalPoint[]} spherical polygon bounding the polar region
def polar_region:
    map(sphere::spherical_flip)
    | map(sphere::spherical_to_cartesian)

    | vb::voronoi_region([0, 0])

    | [ [0, 0], .[] ]
    | project_cell
    | .[1:]

    | map(sphere::spherical_flip)
;

##
# @input {sphericalPoint[]} spherical polygon bounding the polar region
def project_polar_region:
    map({ center: ., radius: sphere::spherical_distance_from([ 0, 0 ]) })
    | map(sphere::circle_to_plane)
    | map(.center)
    | map(sphere::polar_to_cartesian(1))
;

##
# @input {sphericalPoint[]} polar region
def polar_box:
    map(sphere::spherical_flip)
    | map(sphere::spherical_to_cartesian)
    | polygon::biggest_inner_circle([0, 0])
    | circle::biggest_inner_square
    | map(sphere::cartesian_to_spherical)
    | map(sphere::spherical_flip)
    | map(sphere::spherical_to_cartesian)
;

def clip($polygon):
    if polygon::is_polygon_inside($polygon) then
        .
    else
        .[0] as $site
        | .[1:]
        | polygon::edges

        | map(
            if polygon::is_segment_inside($polygon) then
                .
            elif (map(polygon::is_inside($polygon)) | any) then
                # One of segments points in inside polygon
                . as $segment
                | polygon::intersections_segment_polygon($polygon)
                | .[0]

                | if ($segment[0] | polygon::is_inside($polygon)) then
                      [ $segment[0], . ]
                  elif ($segment[1] | polygon::is_inside($polygon)) then
                      [ ., $segment[1] ]
                  else
                      empty
                  end
            else
                # Segment totally outside polygon
                . as $segment
                | polygon::intersections_segment_polygon($polygon)
                | if length > 0 then
                      . as $intersections
                      | $segment
                      | map(. as $p | $intersections | min_by(point::distance_euclidean(.; $p)))
                  else
                      empty
                  end
            end
          )

        | map(.[])

        | sort_by(polygon::angle($site))
        | helpers::collapse_by(polygon::angle($site); .[0])
        | [$site, .[]]
    end
;

##
# @input {sphericalPoint[]} non north pole sites
# @param $northPole {site[0:1]} optional site on the north pole
# @output {cell[]} voronoi diagram of polar region
def north_voronoi($northPole; $polarCell):
    . as $other_sites

    | if ($northPole | length) == 0 then
          map(sphere::spherical_flip)
          | map(sphere::spherical_to_cartesian)

          | . as $sites

          | $polarCell
          | map(sphere::spherical_flip)
          | project_cell_to_plane
          | .[1:] as $polygon

          | [ $sites[], $polygon[] ]
          | rectangle::box as $box

          | $sites
          | fortune::fortune($box)

          | map(clip($polygon))

          # First & last vertexes must be on polygon border
          | map(
                .[0] as $site
                | .[1:]

                | helpers::count(polygon::is_on_border($polygon)) as $nbOnBorder
                | until(
                      .[:$nbOnBorder] | all(polygon::is_on_border($polygon));
                      helpers::rotate_left
                  )

                | [ $site, .[$nbOnBorder-1], .[$nbOnBorder:][], .[0] ]
            )

          | map(project_cell)
          | map(map(sphere::spherical_flip))
      else
          $polarCell
      end
;

##
# Calculate two Rodrigue's rotation matrices (rotation & reverse rotation).
# @input {sphericalPoint} new north pole
# @output {matrix[2]} two Rodrigue's matrices
def rotation_matrices:
    . as $p
    | [ $p[0] - sphere::HALF_PI, sphere::HALF_PI ]
    | sphere::to_3d_cartesian as $axe
    | $p[1] as $angle
    | $axe
    | sphere::cross_product_matrix
    | [ sphere::rotation_matrix($angle), sphere::rotation_matrix(-$angle) ]
;

##
# Rotates a single site using Rodrigue's rotation matrix.
# @input {sphericalPoint} site in spherical coordinates
# @param $R {matrix} Rodrigue's rotation matrix
# @output {sphericalPoint} site translated using matrix
def rotate_site($R):
    sphere::to_3d_cartesian
    | sphere::rotate($R)
    | sphere::from_3d_cartesian
;

##
# Rotates cell around axe using Rodrigue's rotation matrix.
# @input {cell} voronoi cell on the sphere
# @param $R {matrix} Rodrigue's rotation matrix
# @output {cell} translated cell
def rotate_cell($R):
    map(rotate_site($R))
;

##
# Normalizes all sites and vertexes of spherical voronoi diagram.
# @input {cell[]} cells of spherical voronoi diagram
# @output {cell[]} cells of spherical voronoi diagram where all sites & vertexes are normalized
def normalize_voronoi:
    map(map(sphere::normalize))
;

##
# Tests if supplied voronoi diagram covers whole sphere surface (no holes in diagram).
# @input {cell[]} cells of spherical voronoi diagram
# @output {boolean} true - if cells cover whole sphere, false if not
def is_whole:
    def _triangles:
        .[0] as $site
        | .[1:] as $vertexes
        | [ $vertexes[], $vertexes[0] ]
        | helpers::bigrams
        | map([ $site, .[] ])
    ;

    map(_triangles)
    | flatten(1)
    | map(sphere::excess)
    | add
    | . - sphere::UNIT_SPHERE_AREA
    | helpers::abs
    | . < helpers::EPSILON
;

##
# Asserts that supplied voronoi diagram covers whole sphere surface. Throws error if it not the
# case.
# @input {cell[]} cells of spherical voronoi diagram
# @output {cell[]} the same voronoi diagram if it covers the whole sphere surface
def assert_whole:
    if is_whole then
        .
    else
        error("Supplied Voronoi diagram don't cover whole spherical surface !")
    end
;

##
# Returns a voronoi cell that covers whole sphere surface.
# @input {sphericalPoint} site in spherical coordinates
# @output {cell[1]} voronoi cell covering a whole sphere
def _whole_sphere:
    . as $site
    | rotation_matrices as [ $R, $IR ]

    | ( sphere::PI - 0.001 ) as $zenith

    | [
          [ 0, $zenith ],
          [ sphere::HALF_PI, $zenith ],
          [ sphere::PI, $zenith ],
          [ sphere::PI + sphere::HALF_PI, $zenith ]
      ]

    | map(rotate_site($IR))

    | [[ $site, .[] ]]
;

def _slice:
    def _midpoint:
        map(atan2(.[1]; .[0]))
        | [
              .[0],
              helpers::if_else(.[0] <= .[1]; .[1]; .[1] + sphere::TWO_PI)
          ]
        | add
        | . / 2
        | [ cos, sin ]
    ;

    .[1] as $site
    | helpers::bigrams
    | map(_midpoint)
    | map(sphere::cartesian_to_spherical)

    | [
          ( $site | sphere::cartesian_to_spherical ),
          [ 0, sphere::PI ],
          .[0],
          [ 0, 0 ],
          .[1]
      ]
;

##
# Computes voronoi diagram for set of collinear sites on sphere surface. The result diagram looks
# like "orange": the whole sphere is divided in "slices".
# Pre-condition: all supplied sites are collinear on sphere surface.
# @input {sphericalPoint[2:]} sites in spherical coordinates
# @output {cell[]} voronoi diagram
def _orange:
    . as $sites

    | .[:2]
    | map(sphere::to_3d_cartesian)
    | sphere::cross_product
    | sphere::from_3d_cartesian
    | rotation_matrices as [ $R, $IR ]

    | $sites
    | map(rotate_site($R))

    # Order by angle
    | map(sphere::spherical_to_cartesian)
    | sort_by(atan2(.[1]; .[0]))

    | [ .[], .[0], .[1] ]
    | helpers::trigrams
    | map(_slice)

    | map(rotate_cell($IR))
    | normalize_voronoi
    | assert_whole
;

##
# General algorithm for calculation of voronoi diagram on spherical surface.
# Pre-condition: there is at least 3 non-collinear sites among supplied sites.
# @input {sphericalPoint[3:]} sites in spherical coordinates
# @output {cell[]} voronoi diagram
def _spherical_voronoi:
    . as $sites

    | helpers::trigrams
    | map(select(sphere::are_collinear | not))
    | .[0]
    | sphere::centroid
    | rotation_matrices as [ $R, $IR ]

    | $sites
    | map(rotate_site($R))

    | helpers::partitioning_by(sphere::is_spherical_north_pole) as [ $northPole, $notNorthPole ]

    | $notNorthPole
    | polar_cell as $polarCell

    | sphere::projection_limit
    | map(sphere::spherical_to_cartesian) as $box

    | $notNorthPole
    | map(sphere::spherical_to_cartesian)
    | fortune::fortune($box)

    | helpers::partitioning_by(is_bound_cell($box)) as [ $closed, $open ]

    | $closed
    | map(project_cell) as $southPart

    | $open
    | map(remove_vertexes_on_border($box))
    | map(project_cell)
    | sort_by(.[0][1]) as $openCells

    | $open
    | map(.[0])
    | map(sphere::cartesian_to_spherical)
    | north_voronoi($northPole; $polarCell)
    | sort_by(.[0][1]) as $northPart

    | $openCells
    | helpers::zip($northPart)
    | map(merge_two_cells) as $northPart

    | [ $northPart[] ,$southPart[] ]

    | map(rotate_cell($IR))
    | normalize_voronoi
    | assert_whole
;

##
# Computes voronoi diagram on spherical surface.
# @input {sphericalPoint[]} sites in spherical coordinates
# @output {cell[]} voronoi diagram
def spherical_voronoi:
    if length == 0 then
        []
    elif length == 1 then
        .[0]
        | _whole_sphere
    elif length == 2 or ( helpers::trigrams | map(sphere::are_collinear) | all ) then
        _orange
    else
        _spherical_voronoi
    end
;
