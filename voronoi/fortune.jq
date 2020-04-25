module "fortune";

include "helpers";

import "point" as point;
import "line" as line;
import "bstree" as bstree;
import "queue" as queue;
import "parabola" as parabola;
import "circle" as circle;

##
# Implementation of Fortune's algorithm to calculate voronoi diagram.
#
# type site = point & {
#     type: "site",
#     id: string        // site id
# }
#
# type circleEvent = point & circle & {
#     type: "circle",
#     siteId: string,                   // id of disappearing site
#     triplet: [ site, site, site ],    // consecutive arcs creating circle event
#     // x: number,         x coordinate of the bottom point of the circle
#     // y: number,         y coordinate of the bottom point of the circle
#     // center: point,     circle center
#     // radius: number     circle radius
# }
#
# type breakpoint = point & {
#     type: "break",
#     side: "left" | "right",   // side of breakpoint
#     leftSiteId: string,
#     rightSiteId: string
# }
#
# type node_data = site | breakpoint;
#
# type halfedge = {
#     id: string,
#     leftSiteId: string,
#     rightSiteId: string,
#     startPoint: point,
#     endPoint: point,
#     startInfinite: boolean,       // true if half edge is infinite at start
#     endInfinite: boolean          // true if half edge is infinite at end
# }
#
# type cell = {
#     site: site,
#     halfedges: halfedge[]     // counterclockwise ordered array of halfedges
# }
#
# type voronoi = {
#     bstree: node<node_data>,              // binary-search tree
#     events: (site | circleEvent)[],       // event queue
#     seen: [number, number, number][],     // seen triplets
#     sites: {
#         [siteId: string]: site
#     },
#     halfedges: {
#         [halfedgeId: string]: halfedge
#     },
#     cells: {
#         [siteId: string]: cell
#     },
#     id_seed: number
# }
#
# @author hosuaby

##
# Site factory.
# @input {point} point
# @param $id {number} site id
# @output {site} site object
def site($id):
    {
        type: "site",
        id: $id | tostring,
        x: point::x,
        y: point::y
    }
;

##
# Calculates current coordinates of supplied breakpoint.
# Note: breakpoints are always moving during algorithm execution.
# @input {breakpoint} breakpoint
# @param $l {number} y coordinate of the swipe line
# @param $sites {{ [sideId: number]: site }} collection of known sites
# @output {point} coordinates of breakpoint
def break2point($l; $sites):
    . as $breakpoint
    | .side as $side
    | .leftSiteId as $leftSiteId
    | .rightSiteId as $rightSiteId
    | $sites[$leftSiteId] as $leftSite
    | $sites[$rightSiteId] as $rightSite

    | ( $leftSite
        | if point::y < $l then
              parabola::from_point($l)
              | parabola::to_standard_form
          else
              null
          end ) as $parab1

    | ( $rightSite
        | if point::y < $l then
              parabola::from_point($l)
              | parabola::to_standard_form
          else
              null
          end ) as $parab2

    | if $parab1 != null and $parab2 != null then
          parabola::intersections($parab1; $parab2)

          | if length == 2 then
                if $side == "left" then
                    .[0]
                else
                    .[1]
                end
            elif length == 1 then
                ( .[0] | point::x ) as $x
                | ( .[0] | point::y ) as $y

                | if ($leftSite | point::x) <= $x and ($rightSite | point::x) >= $x then
                      # Left site is really on the left and right site really on the right of break
                      .[0]
                  elif $side == "left" then
                      [ MINUS_INFINITY, $y ]      # minus infinity
                  else
                      [ PLUS_INFINITY, $y ]       # plus infinity
                  end
            else
                null    # no intersection
            end
      elif $parab1 != null and $parab2 == null then
          $rightSite
          | point::x
          | [., parabola::eval($parab1)]
      elif $parab1 == null and $parab2 != null then
          $leftSite
          | point::x
          | [., parabola::eval($parab2)]
      else
          null    # no intersection
      end

    | if . != null then
          .
      else
          ( [ $leftSite, $rightSite ] | line::midpoint ) as $midpoint
          | ( $midpoint | point::y ) as $y
          | if ($leftSite | point::x) <= ($rightSite | point::x) then
                $midpoint
            elif $side == "left" then
                [ MINUS_INFINITY, $y ]      # minus infinity
            else
                [ PLUS_INFINITY, $y ]       # plus infinity
            end
      end
;

##
# Compared two nodes of binary search tree.
# @input {[ node_data, node_data ]} data of two nodes of binary-search tree
# @param $l {number} y coordinate of swipe line
# @param $sites {{ [sideId: number]: site }} collection of known sites
# @output negative integer - first node is strictly inferior, 0 - two nodes are equal, positive
#         integer - first node is strictly superior
def compare_nodes($l; $sites):
    map(
        if .type == "break" then
            break2point($l; $sites)
        else
            .
        end
    )
    | point::compare_by_x
;

##
# Creates subtree for inserted ark.
# @input {site} inserted ark
# @param $parent {site | null} parent ark. Can be null
# @output {node<node_data>} created subtree
def make_site_subtree($parent):
    if $parent == null then
        bstree::node(.)
    else
        bstree::node({
                type: "break",
                side: "right",
                leftSiteId: .id,
                rightSiteId: $parent.id
            };
            bstree::node({
                    type: "break",
                    side: "left",
                    leftSiteId: $parent.id,
                    rightSiteId: .id
                };
                bstree::node($parent);
                bstree::node(.));
            bstree::node($parent))
    end
;

##
# Inserts a new site into binary search tree.
# @input {node<node_data> | null} BST. Can be null for empty tree
# @param $site {site} inserted site
# @param $l {number} y coordinate of swipeline
# @param $sites {{ [sideId: number]: site }} map of existing sites
# @output {node<node_data>} updated BST
def insert_site($site; $l; $sites):
    if . == null then
        bstree::node($site)
    elif bstree::is_leaf then
        .data as $data
        | $site
        | make_site_subtree($data)
    else
        if ([ .data, $site ] | compare_nodes($l; $sites)) > 0 then
            setpath([ "left" ]; .left | insert_site($site; $l; $sites))
        else
            setpath([ "right" ]; .right | insert_site($site; $l; $sites))
        end
    end
;

##
# Calculates a side of a new breakpoint formed be left & right ark of triplet of supplied circle
# event.
# @input {circleEvent} circle event
# @onput {"left" | "right"} side of a new break point
def side:
    point::y as $l

    | ( .triplet[0]
        | if point::y < $l then
              parabola::from_point($l)
              | parabola::to_standard_form
          else
              null
          end ) as $parab1
    | ( .triplet[2]
        | if point::y < $l then
              parabola::from_point($l)
              | parabola::to_standard_form
          else
              null
          end ) as $parab2

    | if $parab1 != null and $parab2 != null then
          parabola::intersections($parab1; $parab2) as $breaks
          | if $breaks | length == 2 then
                point::distance_euclidean(.center; $breaks[0]) as $dist1
                | point::distance_euclidean(.center; $breaks[1]) as $dist2

                | if $dist1 < $dist2 then
                      "left"
                  else
                      "right"
                  end
            elif $breaks | length == 1 then
                "left"  # Side doesn't matter
            else
                error("No breaks for \(.triplet[0]) \(.triplet[2]) \($l)")
            end
      elif $parab1 != null and $parab2 == null then
          "left"
      elif $parab1 == null and $parab2 != null then
          "right"
      else      # Both parabolas have 0 focus length
          error("No breaks for \(.triplet[0]) \(.triplet[2]) \($l)")
      end
;

##
# Removes an ark from supplied BST that was shrinked to zero at point $circleEvent.center.
# @input {node<node_data>} node of BST. Can be null for empty tree
# @param $circleEvent {circleEvent} circle event that makes ark disappear
# @param $sites {{ [siteId: string]: site }} map of sites
# @param $prec {node_data | null} data of precedent node to current subtree within global bstree of
#        voronoi object
# @param $next {node_data | null} data of next node to current subtree within global bstree of
#        voronoi object
# @output {node<node_data>} BST with removed ark
def remove_ark($circleEvent; $sites; $prec; $next):
    if bstree::is_leaf then
        if .data.id == $circleEvent.siteId
                and $prec != null and $prec.id == $circleEvent.triplet[0].id
                and $next != null and $next.id == $circleEvent.triplet[2].id then
            null
        else
            .
        end
    else
        ( .left | bstree::last ) as $lastLeft
        | ( .right | bstree::first ) as $firstRight

        | setpath([ "left" ]; .left | remove_ark($circleEvent; $sites; $prec; $firstRight))
        | setpath([ "right" ]; .right | remove_ark($circleEvent; $sites; $lastLeft; $next))

        | if .left == null and .right != null then
              .right
          elif .right == null and .left != null then
              .left
          elif .left == null and .right == null then
              null
          else
              # Both left & right children are present
              ( $circleEvent.triplet | map(.id) ) as $arkIds

              | if .data.leftSiteId == $arkIds[0] and .data.rightSiteId == $arkIds[1] then
                    {
                        data: {
                            type: "break",
                            side: $circleEvent | side,
                            leftSiteId: .data.leftSiteId,
                            rightSiteId: $arkIds[2]
                        },
                        left: .left,
                        right: .right
                    }
                elif .data.leftSiteId == $arkIds[1] and .data.rightSiteId == $arkIds[2] then
                    {
                        data: {
                            type: "break",
                            side: $circleEvent | side,
                            leftSiteId: $arkIds[0],
                            rightSiteId: .data.rightSiteId
                        },
                        left: .left,
                        right: .right
                    }
                else
                    .
                end
          end
    end
;

##
# Finds circle events created by triplets of consecutive arcs (sites) on the beach line.
# Precondition beach line has at least three arcs.
# @input {site[]} beach line
# @output {circleEvent[]} array of calculated circle events
def find_circle_events:
    trigrams
    | map(select(point::are_counterclockwise))
    | map(
        . as $triplet
        | $triplet[1].id as $siteId
        | circle::from_triplet as $circle
        | $circle
        | circle::bottom
        | {
            type: "circle",
            siteId: $siteId,
            triplet: $triplet,
            center: $circle.center,
            radius: $circle.radius,
            x: point::x,
            y: point::y
        })
;

##
# Recalculates circle events. Keeps site events as they are.
# @input {voronoi} voronoi object
# @output {voronoi} updated voronoi object
def recalculate_circle_events:
    ( .bstree | bstree::leaves ) as $beachline
    | ( if ($beachline | length) > 2 then
            $beachline | find_circle_events
        else
            []
        end ) as $circleEvents

    | setpath(
          [ "events" ];
          .events | map(select(.type == "site")) | queue::enqueue_all($circleEvents)
    )
;

##
# Creates a new started half edges for inserted $site.
# @input {voronoi} voronoi object
# @param $site {site} inserted site
# @output {voronoi} updated voronoi object
def start_halfedges($newSite):
    ( .bstree
      | bstree::leaves
      | trigrams
      | .[]
      | select(.[1].id == $newSite.id) ) as $triplet

    | $triplet[0] as $arkSite

    | [
          {
              id: "\($arkSite.id)/\($newSite.id)",
              leftSiteId: $arkSite.id,
              rightSiteId: $newSite.id,
              startPoint: null,
              endPoint: null,
              startInfinite: false,
              endInfinite: false
          },
          {
              id: "\($newSite.id)/\($arkSite.id)",
              leftSiteId: $newSite.id,
              rightSiteId: $arkSite.id,
              startPoint: null,
              endPoint: null,
              startInfinite: false,
              endInfinite: false
          }
      ] as $halfedges

    | setpath(
        [ "halfedges" ];
        .halfedges + ( $halfedges | key_by(.id) )
    )
;

##
# Closes half egdes (at their start or the end) between supplied points during circle event. Totally
# three half edges are formed by converged triplet of arcs. The middle ark disappears as a
# consequence of convergence.
# @input {voronoi} voronoi object
# @param $triplet {[ point, point, point ]} triplet of converged arks
# @param $point {point} convergence point
# @output {voronoi} updated voronoi object
def close_halfedges($triplet; $point):
    $triplet as [ $p1, $p2, $p3 ]

    # Close half edges between $p1 & $p2
    | setpath([ "halfedges", "\($p1.id)/\($p2.id)", "startPoint" ]; $point)
    | setpath([ "halfedges", "\($p2.id)/\($p1.id)", "endPoint" ]; $point)

    # Close half edges between $p2 & $p3
    | setpath([ "halfedges", "\($p2.id)/\($p3.id)", "startPoint" ]; $point)
    | setpath([ "halfedges", "\($p3.id)/\($p2.id)", "endPoint" ]; $point)

    # Create two new halfedges between $p1 & $p3
    | setpath(
        [ "halfedges", "\($p1.id)/\($p3.id)" ];
        {
            id: "\($p1.id)/\($p3.id)",
            leftSiteId: $p1.id,
            rightSiteId: $p3.id,
            startPoint: null,
            endPoint: $point,
            startInfinite: false,
            endInfinite: false
        })
    | setpath(
        [ "halfedges", "\($p3.id)/\($p1.id)" ];
        {
            id: "\($p3.id)/\($p1.id)",
            leftSiteId: $p3.id,
            rightSiteId: $p1.id,
            startPoint: $point,
            endPoint: null,
            startInfinite: false,
            endInfinite: false
        })
;

##
# Clips supplied halfedge using Liang-Barsky algorithm.
# @input {halfedge} halfedge
# @output {halfedge} clipped halfedge
def clip_halfedge($boundaries):
    . as $halfedge
    | [ .startPoint, .endPoint ]
    | line::clip($boundaries) as $clipped
    | $halfedge

    | if point::equals(.startPoint; $clipped[0]) | not then
          setpath([ "startPoint" ]; $clipped[0])
          | setpath([ "startInfinite" ]; true)
      else
          .
      end

    | if point::equals(.endPoint; $clipped[1]) | not then
          setpath([ "endPoint" ]; $clipped[1])
          | setpath([ "endInfinite" ]; true)
      else
          .
      end
;

##
# Clips all halfedges of voronoi object.
# @input {voronoi} voronoi object
# @param $boundaries {[ point, point ]} two points defining the bounding box
# @output {voronoi} updated voronoi object
def clip_halfedges($boundaries):
    setpath(
        [ "halfedges" ];
        .halfedges
        | map(select(.startPoint != null and .endPoint != null))
        | map(clip_halfedge($boundaries))
    )
;

##
# Handles a site event.
# @input {voronoi} voronoi object
# @param $site {site} site event
# @output {voronoi} updated voronoi object
def handle_site_event($site):
    .sites as $sites
    | ( $site | point::y ) as $l
    | setpath([ "bstree" ]; .bstree | insert_site($site; $l; $sites) | bstree::rebalance)
    | recalculate_circle_events

    # Create a new edge
    | if .bstree | bstree::is_leaf | not then
          start_halfedges($site)
      else
          .
      end
;

##
# Handles a circle event.
# @input {voronoi} voronoi object
# @param $circleEvent {circleEvent} circle event
# @output {voronoi} updated voronoi object
def handle_circle_event($circleEvent):
    .sites as $sites
    | setpath(
          [ "bstree" ];
          .bstree | remove_ark($circleEvent; $sites; null; null) | bstree::rebalance
      )

    # Close edges of disappeared site
    | close_halfedges($circleEvent.triplet; $circleEvent.center)

    | recalculate_circle_events
;

##
# Closes an unclosed half edge finding its intersection with bounding box.
# Precondition: supplied half edge has endPoint set to null and may to have or not to have
# startPoint set to null.
# @input {halfedge} half edge
# @param $sites {{ [siteId: string]: site }} map of sites
# @param $boundaries {[ point, point ]} two points defining the bounding box
# @output {halfedge} updated half edge
def close_halfedge($sites; $boundaries):
    . as $halfedge
    | $sites[.leftSiteId] as $leftSite
    | $sites[.rightSiteId] as $rightSite
    | ( $leftSite | point::x ) as $lsX
    | ( $leftSite | point::y ) as $lsY
    | ( $rightSite | point::x ) as $rsX
    | ( $rightSite | point::y ) as $rsY
    | ( $boundaries[0] | point::x ) as $minX
    | ( $boundaries[0] | point::y ) as $minY
    | ( $boundaries[1] | point::x ) as $maxX
    | ( $boundaries[1] | point::y ) as $maxY

    | ( [ $leftSite, $rightSite ] | line::midpoint ) as $midpoint
    | ( $midpoint | point::x ) as $midX
    | ( $midpoint | point::y ) as $midY

    # Start by check special cases where edge is strictly horizontal or vertical
    | if $lsX == $rsX and $lsY > $rsY then
          # Strictly leftward
          [ [$maxX, $midY], [$minX, $midY] ]
      elif $lsX == $rsX and $lsY < $rsY then
          # Strictly rightward
          [ [$minX, $midY], [$maxX, $midY] ]
      elif $lsX < $rsX and $lsY == $rsY then
          # Strictly upward
          [ [$midX, $maxY], [$midX, $minY] ]
      elif $lsX > $rsX and $lsY == $rsY then
          # Strinctly downward
          [ [$midX, $minY], [$midX, $maxY] ]
      else
          # Find expression of the line by x in Gradient-Intercept form
          (
              if .startPoint != null and (point::equals(.startPoint; $midpoint) | not) then
                  # Half edge can be traced between startPoint & $midpoint
                  [ .startPoint, $midpoint ] | line::to_gradient_intercept_form
              else
                  # Half edge is perpendicular to line segment between two sites
                  [ $leftSite, $rightSite ]
                  | line::to_gradient_intercept_form
                  | line::perpendicular($midpoint)
              end
          ) as $line_by_x

          | ( $line_by_x | line::form_by_y ) as $line_by_y

          # Find intersection of the line with all four borders of the box.
          # All four intersections are guaranteed to exist as line is not strictly vertical or
          # horizontal.
          | ( $line_by_x | line::eval($minX) ) as $leftBorderY
          | ( $line_by_x | line::eval($maxX) ) as $rightBorderY
          | ( $line_by_y | line::eval($minY) ) as $topBorderX
          | ( $line_by_y | line::eval($maxY) ) as $bottomBorderX

          | if $lsX < $rsX and $lsY > $rsY then
                # Left-upward
                if $leftBorderY >= $minY then
                    [$minX, $leftBorderY]
                else
                    [$topBorderX, $minY]
                end
            elif $lsX < $rsX and $lsY < $rsY then
                # Right-upward
                if $rightBorderY >= $minY then
                    [$maxX, $rightBorderY]
                else
                    [$topBorderX, $minY]
                end
            elif $lsX > $rsX and $lsY < $rsY then
                # Right-downward
                if $rightBorderY <= $maxY then
                    [$maxX, $rightBorderY]
                else
                    [$bottomBorderX, $maxY]
                end
            else
                # Left-downward
                if $leftBorderY <= $maxY then
                    [$minX, $leftBorderY]
                else
                    [$bottomBorderX, $maxY]
                end
            end
          | . as $endPoint

          | if $halfedge.startPoint == null then
                if $lsX < $rsX and $lsY > $rsY then
                    # Left-upward
                    if $rightBorderY <= $maxY then
                        [$maxX, $rightBorderY]
                    else
                        [$bottomBorderX, $maxY]
                    end
                elif $lsX < $rsX and $lsY < $rsY then
                    # Right-upward
                    if $leftBorderY <= $maxY then
                        [$minX, $leftBorderY]
                    else
                        [$bottomBorderX, $maxY]
                    end
                elif $lsX > $rsX and $lsY < $rsY then
                    # Right-downward
                    if $leftBorderY >= $minY then
                        [$minX, $leftBorderY]
                    else
                        [$topBorderX, $minY]
                    end
                else
                    # Left-downward
                    if $rightBorderY >= $minY then
                        [$maxX, $rightBorderY]
                    else
                        [$topBorderX, $minY]
                    end
                end
            else
                $halfedge.startPoint
            end
          | . as $startPoint

          | [ $startPoint, $endPoint ]
      end

    # Reset startPoint if half edge originally has it
    | if $halfedge.startPoint != null then
          [ $halfedge.startPoint, .[1] ]
      else
          .
      end

    | . as [ $startPoint, $endPoint ]
    | $halfedge
    | setpath([ "startPoint" ]; $startPoint)
    | setpath([ "endPoint" ]; $endPoint)
;

##
# Cleans up halfedges where startPoint equals endPoint. This operation is necessary to be able
# reorder halfedges later.
# @input {voronoi} voronoi object
# @output {voronoi} updated voronoi object
def remove_zero_length_halhedges:
    setpath([ "halfedges" ];
        .halfedges
        | values
        | map(select(
              .startPoint != null
              and .endPoint != null
              and point::are_close(.startPoint; .endPoint) | not))
        | key_by(.id)
    )
;

##
# Closes all unclosed half edges.
# @input {voronoi} voronoi object
# @param $boundaries {[ point, point ]} two points defining the bounding box
# @output {voronoi} updated voronoi object
def close_unclosed_half_edges($boundaries):
    . as $voronoi
    | .sites as $sites
    | .halfedges
    | values

    # We only need to find endPoints of half edges open by the end. Those same endPoints will be at
    # the same time startPoints of twin half edges
    | map(select(.endPoint == null))
    | map(close_halfedge($sites; $boundaries))

    | reduce .[] as $closedHalfedge (
        $voronoi;
        setpath([ "halfedges", $closedHalfedge.id ]; $closedHalfedge)
        | setpath([
            "halfedges",
            "\($closedHalfedge.rightSiteId)/\($closedHalfedge.leftSiteId)",
            "startPoint"
        ]; $closedHalfedge.endPoint))
;

##
# Orders the half edges in counter clockwise order where the endpoint of the precedent half edge is
# a start point of the following half edge.
# Precondition: supplied array must contain more than 2 half edges
# @input {halfedge[]} array of unordered half edges forming closed cell
# @output {halfedge[]} array of ordered half edges forming closed cell
def order_halfedges:
    {
        ordered: [ .[0] ],
        rest: .[1:]
    }
    | until((.rest | length) == 0;
          ( .ordered[-1] | .endPoint ) as $lastPoint
          | ( .rest | find_first(point::equals($lastPoint; .startPoint)) ) as $found
          | if $found != null then
               $found as [ $nextHalfedge, $i ]
               | {
                     ordered: (.ordered + [ $nextHalfedge ]),
                     rest: ( .rest[:$i] + .rest[$i+1:] )
                 }
            else
                error("Cannot order half edges, cell is not closed!")
            end
      )
    | .ordered
;

##
# Creates cells from closed half edges.
# @input {voronoi} voronoi object
# @param $boundaries {[ point, point ]} two points defining the bounding box
# @output {voronoi} updated voronoi object
def create_cells($boundaries):
    reduce (.sites | keys | .[]) as $siteId (
        .;      # voronoi

        # Select half edges of site
        ( .halfedges
          | values
          | map(select(.leftSiteId == $siteId)) ) as $halfedges

        | {
              site: .sites[$siteId],
              halfedges: $halfedges
          } as $cell

        | setpath([ "cells", $siteId ]; $cell)
    )
;

##
# Adds half edges to close supplied cell.
# @input {cell} cell to close
# @param $boundaries {[ point, point ]} two points defining the bounding box
# @output {cell} closed cell
def close_cell($boundaries):

    ##
    # type state = {
    #     top: point[],
    #     bottom: point[],
    #     left: point[],
    #     right: point[],
    #     starts: point[],
    #     ends: point[]
    # }

    ##
    # Adds a new start point to state object.
    # @input {state} state object
    # @output {state} updated state object
    def add_start($startPoint):
        setpath([ "starts" ]; .starts + [ $startPoint ])
    ;

    ##
    # Adds a new end point to state object.
    # @input {state} state object
    # @output {state} updated state object
    def add_end($endPoint):
        setpath([ "ends" ]; .ends + [ $endPoint ])
    ;

    ##
    # Inserts provided $point into right border of supplied state object.
    # @input {state} state object
    # @param $point {point} point to insert
    # @param $borders {[ minX: number, minY: number, maxX: number, maxY: number ]} borders
    # @output {state} updated state object
    def insert_in_border($point; $borders):
        ( $point | point::x ) as $x
        | ( $point | point::y ) as $y
        | $borders as [ $minX, $minY, $maxX, $maxY ]

        | if $y == $minY then
              # Top
              setpath([ "top" ]; .top + [ $point ])
          elif $x == $minX then
              # Left
              setpath([ "left" ]; .left + [ $point ])
          elif $y == $maxY then
              # Bottom
              setpath([ "bottom" ]; .bottom + [ $point ])
          else
              # Right
              setpath([ "right" ]; .right + [ $point ])
          end
    ;

    ##
    # Looks for end point, situated on the border of voronoi diagram, next to provided $start point.
    # Border points are counter-clockwise ordered and forms a closed square.
    # @input {point[]} array of counter-clockwise ordered points situated on the borders of voronoi
    #        diagram
    # @param $start {point} start point
    # @param $endPoints {point[]} know end points
    # @output {point} found end point
    def find_end($start; $endPoints):
        . as $orderedPoints

        | ( find_first(point::equals(.; $start)) | .[1] ) as $startIndex
        | cyclic_indexes($startIndex)
        | map([$orderedPoints[.], .])
        | find_first(.[0] as $point | $endPoints | any(point::equals(.; $point)))
        | .[0]
    ;

    . as $cell
    | ( $boundaries[0] | point::x ) as $minX
    | ( $boundaries[0] | point::y ) as $minY
    | ( $boundaries[1] | point::x ) as $maxX
    | ( $boundaries[1] | point::y ) as $maxY
    | [ $minX, $minY, $maxX, $maxY ] as $borders

    | {
          top: [ [$maxX, $minY], [$minX, $minY] ],
          bottom: [ [$minX, $maxY], [$maxX, $maxY] ],
          left: [ [$minX, $minY], [$minX, $maxY] ],
          right: [ [$maxX, $maxY], [$maxX, $minY] ],
          starts: [],
          ends: []
      }

    | reduce $cell.halfedges[] as $halfedge (
          .;

          if $halfedge.startInfinite then
              add_end($halfedge.startPoint)
              | insert_in_border($halfedge.startPoint; $borders)
          else
              .
          end

          | if $halfedge.endInfinite then
                add_start($halfedge.endPoint)
                | insert_in_border($halfedge.endPoint; $borders)
            else
                .
            end
      )

    | {
          top: .top | sort_by(point::x) | reverse,
          bottom: .bottom | sort_by(point::x),
          left: .left | sort_by(point::y),
          right: .right | sort_by(point::y) | reverse,
          starts,
          ends
      }

    | reduce .starts[] as $start (
          {
              orderedPoints: ( .top[:-1] + .left[:-1] + .bottom[:-1] + .right[:-1] ),
              halfedges: [],
              starts,
              ends
          };

          .ends as $ends
          | .orderedPoints as $orderedPoints
          | ( $orderedPoints | find_first(point::equals(.; $start)) | .[1] ) as $startIndex
          | ( $orderedPoints | find_end($start; $ends) | .[1] ) as $endIndex

          | ( $orderedPoints
              | extract(cyclic_indexes($startIndex; $endIndex))
              | bigrams
              | map({ startPoint: .[0], endPoint: .[1] }) ) as $newHalfedges
          | setpath([ "halfedges" ]; .halfedges + $newHalfedges)

          # Remove used start and end points
          | setpath([ "orderedPoints" ]; .orderedPoints | del(.[$startIndex, $endIndex]))
      )

    | ( .halfedges | map(select(point::equals(.startPoint; .endPoint) | not)) ) as $newHalfedges

    | $cell
    | setpath([ "halfedges" ]; .halfedges + $newHalfedges)
;

##
# Adds halfedges to close unbound cells.
# @input {voronoi} voronoi object
# @param $boundaries {[ point, point ]} two points defining the bounding box
# @output {voronoi} updated voronoi object
def close_unbound_cells($boundaries):
    . as $voronoi
    | ( .cells
        | values
        | map(select(any(.halfedges[]; .startInfinite or .endInfinite)))
        | map(close_cell($boundaries)) ) as $closedCells

    | reduce $closedCells[] as $cell ($voronoi; setpath([ "cells", $cell.site.id ]; $cell))
;

##
# Reorders half edges of closed cell in counter-clockwise order.
# @input {voronoi} voronoi object
# @output {voronoi} updated voronoi object
def reorder_cells_halfedges:
    . as $voronoi
    | .cells
    | values
    | map(setpath([ "halfedges" ];
          .site.id as $id
          | .halfedges
          | try
                order_halfedges
            catch
                error("Cell \($id) is not closed!")))
    | reduce .[] as $cell ($voronoi; setpath([ "cells", $cell.site.id ]; $cell))
;

##
# Executes Fortune's algorithm.
# @input {point[]} array of site points
# @param $boundaries {[ point, point ]} two points defining rectangle delimiting space where voronoi
# must be calculated
def fortune($boundaries):
    if length == 1 then
        # Degenerate case with a single site
        ( $boundaries[0] | point::x ) as $minX
        | ( $boundaries[0] | point::y ) as $minY
        | ( $boundaries[1] | point::x ) as $maxX
        | ( $boundaries[1] | point::y ) as $maxY

        | [[ .[0], [$maxX, $minY], [$minX, $minY], [$minX, $maxY], [$maxX, $maxY] ]]
    else

      # Create the initial state
      reduce .[] as $input (
          # Initial state
          {
              bstree: null,
              events: [],
              seen: [],
              sites: {},
              halfedges: {},
              cells: {},
              id_seed: 0
          };

          .id_seed as $siteId
          | ( $input | site($siteId) ) as $site
          | {
              bstree,
              halfedges,
              cells,
              seen,
              events: .events | queue::enqueue($site),
              sites: .sites | setpath([ $siteId | tostring ]; $site),
              id_seed: ( $siteId + 1 )
          }
      )

      # Process event queue
      | until(.events | queue::is_empty;
          . as $state     # store current state
          | .sites as $sites

          # Dequeue next event
          | [ .events | queue::dequeue(point::compare_by_y) ] as [ $event, $queue ]
          | ( $event | point::y ) as $l
          | setpath([ "events" ]; $queue)

          # Process event
          | if $event.type == "site" then
                handle_site_event($event)
            else    # type == "circle"
                ( $event.triplet | map(.id) | sort ) as $ids
                | if .seen | any(. == $ids) | not then
                      # Not seen this triplet again
                      handle_circle_event($event)
                      | setpath([ "seen" ]; .seen + [$ids])   # mark triplet as seen
                  else
                      .   # do nothing
                  end
            end
      )

      # Mark unclosed half edges as infinite
      | reduce (.halfedges | values | .[]) as $halfedge (
            .;  # voronoi object

            if $halfedge.startPoint == null then
                setpath([ "halfedges", $halfedge.id, "startInfinite" ]; true)
            else
                .
            end

            | if $halfedge.endPoint == null then
                  setpath([ "halfedges", $halfedge.id, "endInfinite" ]; true)
              else
                  .
              end
        )

      | close_unclosed_half_edges($boundaries)

      | clip_halfedges($boundaries)

      | remove_zero_length_halhedges

      | create_cells($boundaries)

      | close_unbound_cells($boundaries)

      | reorder_cells_halfedges

      # Output result
      | .cells
      | values
      | map(
            [[ (.site | point::x), (.site | point::y) ]]     # site
            +
            # Array of counterclockwise ordered vertices of polygon forming the cell of the site
            ( .halfedges | map(.startPoint | [point::x, point::y]) )
        )
    end
;
