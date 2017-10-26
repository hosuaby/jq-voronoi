module "fortune";

import "point" as point;
import "line" as line;
import "bstree" as bstree;
import "queue" as queue;
import "parabola" as parabola;
import "circle" as circle;
import "helpers" as helpers;

##
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
# Constructor.
# @param $id site id
# @param $point coordinates
# @output site object
# TODO: use this method
def site($id; $point):
    {
        type: "site",
        id: $id | tostring,
        x: $point | x,
        y: $point | y
    }
;

##
# Calculates current coordinates of supplied breakpoint.
# Note: breakpoints are always moving during algorithm execution.
# @input {breakpoint} breakpoint
# @param $l {number} y coordinate of the swipe line
# @param $sites {{ [sideId: number]: site }} collection of known sites
# @output {point} coordinates of breakpoint
def _break2point($l; $sites):
    . as $breakpoint
    | .side as $side
    | .leftSiteId as $leftSiteId
    | .rightSiteId as $rightSiteId
    | $sites[$leftSiteId] as $leftSite
    | $sites[$rightSiteId] as $rightSite

    | { focus: $leftSite, directrix: $l }
    | ( try
            parabola::to_standard_form
        catch
            null ) as $parab1

    | { focus: $rightSite, directrix: $l }
    | ( try
            parabola::to_standard_form
        catch
            null ) as $parab2

    | if $parab1 != null and $parab2 != null then
          parabola::intersections($parab1; $parab2)
      elif $parab1 != null and $parab2 == null then
          $rightSite | point::x | [ [., parabola::eval($parab1)] ]
      elif $parab1 == null and $parab2 != null then
          $leftSite | point::x | [ [., parabola::eval($parab2)] ]
      else
          []    # no intersection
      end

    | if length == 1 then
          ( .[0] | point::x ) as $x
          | ( .[0] | point::y ) as $y

          | if ($leftSite | point::x) <= $x and ($rightSite | point::x) >= $x then
                .[0]
            elif $side == "left" then
                # Minus infinity
                [-99999999, $y]
            else
                # Plus infinity
                [99999999, $y]
            end
      elif length == 2 then
          # If parabolas intersect in two points we only keep point between left and right site
          if $side == "left" then
              .[0]
          else
              .[1]
          end
      else
          # No parabola intersection
          ( [ $leftSite, $rightSite ] | point::midpoint ) as $midpoint
          | ( $midpoint | point::y ) as $y
          | if ($leftSite | point::x) <= ($rightSite | point::x) then
                $midpoint
            elif $side == "left" then
                # Minus infinity
                [-99999999, $y]
            else
                # Plus infinity
                [99999999, $y]
            end

          #error("Cannot find breakpoint. Left site: \($leftSite). Right site: \($rightSite). "
          #    + "L: \($l)")
      end
;

##
# Function comparing two points. Points are compared first by x, after if equal by y coordinate.
# @input [ point1: point, point2: point ] array with two points
# @output negative integer - first point is strictly inferior, 0 - two points are equal, positive
#         integer - first point is strictly superior
def x_comparator:
    . as [ $p1, $p2 ]
    | ( $p1 | point::x ) as $x1
    | ( $p1 | point::y ) as $y1
    | ( $p2 | point::x ) as $x2
    | ( $p2 | point::y ) as $y2

    | ( $x1 - $x2 ) as $Dx
    | if $Dx == 0 then
        $y1 - $y2
      else
        $Dx
      end
;

##
# Function comparing two points. Points are compared first by y, after if equal by x coordinate.
# @input [ point1: point, point2: point ] array with two points
# @output negative integer - first point is strictly inferior, 0 - two points are equal, positive
#         integer - first point is strictly superior
def y_comparator:
    . as [ $p1, $p2 ]
    | ( $p1 | point::x ) as $x1
    | ( $p1 | point::y ) as $y1
    | ( $p2 | point::x ) as $x2
    | ( $p2 | point::y ) as $y2

    | ( $y1 - $y2 ) as $Dy
    | if $Dy == 0 then
        $x1 - $x2
      else
        $Dy
      end
;

##
# Function comparing two nodes of binary-search tree.
# @input [ node_data, node_data ] two nodes of binary-search tree
# @param $l: number y coordinate of swipe line
# @param $sites: { [sideId: number]: site } collection of known sites
# @output negative integer - first node is strictly inferior, 0 - two nodes are equal, positive
#         integer - first node is strictly superior
def bs_comparator($l; $sites):
    map(
        if .type == "break" then
            _break2point($l; $sites)
        else
            .
        end
    )
    | x_comparator
;

##
# @input data of a new node
# @param $parent: [ object | null, "left" | "right" ] data on the parent node and where a new node
#        must be inserted
# @output created subtree
# TODO: remake signature
def make_subtree($parent):
    if $parent[0] == null then
        bstree::node(.)
    elif $parent[1] == "left" then
        bstree::node({
                type: "break",
                side: "right",
                leftSiteId: .id,
                rightSiteId: $parent[0].id
            };
            bstree::node({
                    type: "break",
                    side: "left",
                    leftSiteId: $parent[0].id,
                    rightSiteId: .id
                };
                bstree::node($parent[0]);
                bstree::node(.));
            bstree::node($parent[0]))
    else    # right
        bstree::node({
                type: "break",
                side: "left",
                leftSiteId: $parent[0].id,
                rightSiteId: .id
            };
            bstree::node($parent[0]);
            bstree::node({
                    type: "break",
                    side: "right",
                    leftSiteId: .id,
                    rightSiteId: $parent[0].id
                };
                bstree::node(.);
                bstree::node($parent[0])))
    end
;

##
# TODO: remake comment
# @input BST
# @param $site inserted site
# @param $l y coordinate of swipeline
# @param $sites map of existing sites
# @output updated BST
def insert_site($site; $l; $sites):
    if . == null then
        bstree::node($site)
    elif bstree::is_leaf then
        .data as $data
        | if ([ $data, $site ] | x_comparator) > 0 then
              $site | make_subtree([ $data, "left" ])
          else
              $site | make_subtree([ $data, "right" ])
          end
    else
        if ([ .data, $site ] | bs_comparator($l; $sites)) > 0 then
            setpath(
                [ "left" ];
                .left as $left
                | if $left | bstree::is_leaf then
                      $site | make_subtree([ $left.data, "left" ])
                  else
                      $left | insert_site($site; $l; $sites)
                  end
            )
        else
            setpath(
                [ "right" ];
                .right as $right
                | if $right | bstree::is_leaf then
                      $site | make_subtree([ $right.data, "right" ])
                  else
                      $right | insert_site($site; $l; $sites)
                  end
            )
        end
    end
;

##
# TODO: check doc
# Removes an ark from supplied BST that was shrinked to zero at point $circleEvent.center.
# @input {node} root node of BST. Can be null for empty tree
# @param $circleEvent {circleEvent} circle event that makes ark disappear
# @param $sites {{ [siteId: string]: site }} map of sites
# @output {node} BST with removed ark
def remove_ark($circleEvent; $sites; $prec; $next):
    if bstree::is_leaf then
        if .data.id == $circleEvent.siteId
                and $prec != null and $prec.id == $circleEvent.triplet[0].id
                and $next != null and $next.id == $circleEvent.triplet[2].id then
            # Found, remove this ark
            null
        else
            .
        end
    else
        ( .left | bstree::leaves | .[-1] ) as $lastLeft
        | ( .right | bstree::leaves | .[0] ) as $firstRight

        | setpath([ "left" ]; .left | remove_ark($circleEvent; $sites; $prec; $firstRight))
        | setpath([ "right" ]; .right | remove_ark($circleEvent; $sites; $lastLeft; $next))

        | if .left == null and .right != null then
              .right
          elif .right == null and .left != null then
              .left
          elif .left == null and .right == null then
              null
          else
              .
          end
    end
;

##
# Finds circle events created by triplets of consecutive arcs (sites) on the beach line.
# Precondition beach line has at least three arcs.
# @input site[] beach line
# @output circleEvent[] array of calculated circle events
def find_circle_events:
    helpers::triplets
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
            x: . | point::x,
            y: . | point::y
        })
;

##
# Recalculates circle events. Keeps site events as they are.
# @input voronoi voronoi object
# @output updated voronoi object
def recalculate_circle_events:
    ( .bstree | bstree::leaves ) as $beachline
    | ( if ($beachline | length) > 2 then
            $beachline | find_circle_events
        else
            []
        end ) as $circleEvents

    | setpath(
          [ "events" ];
          ( .events | map(select(.type == "site")) ) + $circleEvents
    )
;

def start_halfedges($newSite):
    ( .bstree
      | bstree::leaves
      | helpers::triplets
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
        .halfedges + ( $halfedges | helpers::key_by(.id) )
    )
;

def close_halfedges($triplet; $point):
    $triplet as [ $p1, $p2, $p3 ]

    | setpath([ "halfedges", "\($p1.id)/\($p2.id)", "startPoint" ]; $point)
    | setpath([ "halfedges", "\($p2.id)/\($p1.id)", "endPoint" ]; $point)

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
# Handles the site event.
# @input voronoi voronoi object
# @param $site site event
# @output updated voronoi object
def handle_site_event($site):
    .sites as $sites
    | ( $site | point::y ) as $l
    | setpath([ "bstree" ]; .bstree | insert_site($site; $l; $sites))
    | recalculate_circle_events

    # Create a new edge
    | if .bstree | bstree::is_leaf | not then
          start_halfedges($site)
      else
          .
      end
;

##
# Handles the circle event.
# @input voronoi voronoi object
# @param $circleEvent circle event
# @output updated voronoi object
def handle_circle_event($circleEvent):
    .sites as $sites
    | setpath([ "bstree" ]; .bstree | remove_ark($circleEvent; $sites; null; null))

    # Close edges of disappeared site
    | close_halfedges($circleEvent.triplet; $circleEvent.center)
    | ( .events
        | map(select(.type == "circle" and .siteId == $circleEvent.siteId))) as $otherEvents

    #| reduce $otherEvents[] as $event (.; close_halfedges($event.triplet; $event.center))


    #| close_halfedges($circleEvent.triplet; $circleEvent.center)

    | recalculate_circle_events
;

##
# Precondition: supplied half edge has endPoint set to null and may to have or not to have startPoint set
# to null.
# @input {halfedge} half edge
# @param $sites {{ [siteId: string]: site }} map of sites
# @param $boundaries {[ point, point ]} two points defining the bounding box
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

    | ( [ $leftSite, $rightSite ] | point::midpoint ) as $midpoint
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
                  [ .startPoint, $midpoint ] | point::to_gradient_intercept_form
              else
                  # Half edge is perpendicular to line segment between two sites
                  [ $leftSite, $rightSite ]
                  | point::to_gradient_intercept_form
                  | point::perpendicular($midpoint)
              end
          ) as $line_by_x

          | ( $line_by_x | point::form_by_y ) as $line_by_y

          # Find intersection of the line with all four borders of the box.
          # All four intersections are garranted to exist as line is not strictly vertical or
          # horizontal.
          | ( $line_by_x | point::eval_line($minX) ) as $leftBorderY
          | ( $line_by_x | point::eval_line($maxX) ) as $rightBorderY
          | ( $line_by_y | point::eval_line($minY) ) as $topBorderX
          | ( $line_by_y | point::eval_line($maxY) ) as $bottomBorderX

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
# @input {voronoi} voronoi state object
# @output {voronoi} updated voronoi state object
def remove_zero_length_halhedges:
    setpath([ "halfedges" ];
        .halfedges
        | helpers::values
        | map(select(
              .startPoint != null
              and .endPoint != null
              and point::equals(.startPoint; .endPoint) | not))
        | helpers::key_by(.id)
    )
;

##
# @input {voronoi} voronoi state object
def close_half_infinite_edges($boundaries):
    . as $voronoi
    | .sites as $sites
    | .halfedges
    | helpers::values

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
          | ( .rest | helpers::find_first(point::close($lastPoint; .startPoint)) ) as $found
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

def create_cells($boundaries):
    . as $voronoi
    | reduce (.sites | keys | .[]) as $siteId (
          $voronoi;

          # Select half edges of site
          ( .halfedges
            | values
            | map(select(.leftSiteId == $siteId))
            #| map(clip_halfedge($boundaries))
            ) as $halfedges

          | {
                site: $voronoi.sites[$siteId],
                halfedges: $halfedges
            } as $cell

          | setpath([ "cells", $siteId ]; $cell)
    )
;

##
# @input {cell} cell to close
def close_cell($boundaries):
    def add_start($startPoint):
        setpath([ "starts" ]; .starts + [ $startPoint ])
    ;

    def add_end($endPoint):
        setpath([ "ends" ]; .ends + [ $endPoint ])
    ;

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

    def find_end($start; $endPoints):
        . as $orderedPoints

        | [$start, $endPoints] | $orderedPoints

        | ( helpers::find_first(point::equals(.; $start)) | .[1] ) as $startIndex
        | helpers::cyclic_indexes($startIndex)
        | map([$orderedPoints[.], .])
        | helpers::find_first(.[0] as $point | $endPoints | any(point::equals(.; $point)))
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
          | ( $orderedPoints | helpers::find_first(point::equals(.; $start)) | .[1] ) as $startIndex
          | ( $orderedPoints | find_end($start; $ends) | .[1] ) as $endIndex

          | ( $orderedPoints
              | helpers::extract(helpers::cyclic_indexes($startIndex; $endIndex))
              | helpers::pairs
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
# @input {voronoi}
def close_unbound_cells($boundaries):
    . as $voronoi
    | ( .cells
        | helpers::values
        | map(select(any(.halfedges[]; .startInfinite or .endInfinite)))
        | map(close_cell($boundaries)) ) as $closedCells

    | reduce $closedCells[] as $cell ($voronoi; setpath([ "cells", $cell.site.id ]; $cell))
;

##
# @input {voronoi}
def reorder_cells_halfedges:
    . as $voronoi
    | .cells
    | helpers::values
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
# @input array of site points
# @param $boundaries [ point, point ] two points defining rectangle delimiting space where voronoi
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

          .id_seed as $site_id
          | ( $input | { type: "site", id: $site_id | tostring, x: .[0], y: .[1] } ) as $site
          | {
              bstree,
              halfedges,
              cells,
              seen,
              events: .events | queue::enqueue($site),
              sites: .sites | setpath([ $site_id | tostring ]; $site),
              id_seed: ( $site_id + 1 )
          }
      )

      # Process event queue
      | until(.events | queue::is_empty;
          . as $state     # store current state
          | .sites as $sites

          # Dequeue next event
          | [ .events | queue::dequeue(y_comparator) ] as [ $event, $queue ]
          | ( $event | point::y ) as $l
          | setpath([ "events" ]; $queue)

          # Process site event
          | if $event.type == "site" then
                handle_site_event($event)
            else
                ( $event.triplet | map(.id) | sort ) as $ids
                # TODO: refactor check for seen triplets in handle_circle_event method
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
      | . as $voronoi
      | reduce (.halfedges | values | .[]) as $halfedge (
            $voronoi;

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

      # Clean up of halfedges with zero length, necessary in some degenerate cases
      | remove_zero_length_halhedges

      | close_half_infinite_edges($boundaries)
      # TODO: put clip edges here

      | create_cells($boundaries)

      | close_unbound_cells($boundaries)

      | reorder_cells_halfedges

      # Output result
      | .cells
      | helpers::values
      | map(
            [[ (.site | point::x), (.site | point::y) ]]     # site
            +
            # Array of counterclockwise ordered vertices of polygon forming the cell of the site
            ( .halfedges | map([ (.startPoint | point::x), (.startPoint | point::y) ]) )
        )
      #| "done"
    end
;
