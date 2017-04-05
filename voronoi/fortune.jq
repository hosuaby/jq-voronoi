module "fortune";

include "point";
include "bstree";
include "queue";

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
#     events: (site | circleEvent)[],       // event queue
#     bstree: node<node_data>,      // binary-search tree
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
# @input breakpoint
# @param $l: number y coordinate of swipe line
# @param $sites: { [sideId: number]: site } collection of known sites
# @output point of intersection between two parabolas
# TODO: check if it's possible to avoid use of getpath
def _break2point($l; $sites):
    . as $breakpoint
    | .side as $side
    | .leftSiteId as $leftSiteId
    | ( $sites | getpath([ $leftSiteId ]) ) as $leftSite
    | $breakpoint

    | .rightSiteId as $rightSiteId
    | ( $sites | getpath([ $rightSiteId ]) ) as $rightSite
    | $breakpoint

    | { focus: $leftSite, directrix: $l } | parabola::to_standard_form as $parab1
    | { focus: $rightSite, directrix: $l } | parabola::to_standard_form as $parab2

    | parabola::intersections($parab1; $parab2)

    # If parabolas intersect in two points we only keep point between left and right site

    | if length == 1 then
          .
      else
          if $side == "left" then
              .[0]
          else
              .[1]
          end
      end
;

##
# Function comparing two points. Points are compared first by x, after if equal by y coordinate.
# @input [ point1: point, point2: point ] array with two points
# @output negative integer - first point is strictly inferior, 0 - two points are equal, positive
#         integer - first point is strictly superior
def x_comparator:
    . as [ $p1, $p2 ]
    | ( $p1 | x ) as $x1
    | ( $p1 | y ) as $y1
    | ( $p2 | x ) as $x2
    | ( $p2 | y ) as $y2

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
    | ( $p1 | x ) as $x1
    | ( $p1 | y ) as $y1
    | ( $p2 | x ) as $x2
    | ( $p2 | y ) as $y2

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
        if .type == "site" then
            .
        else    # It's a breakpoint
            _break2point($l; $sites)
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
        node(.)
    elif $parent[1] == "left" then
        node({
                type: "break",
                side: "right",
                leftSiteId: .id,
                rightSiteId: $parent[0].id
            };
            node({
                    type: "break",
                    side: "left",
                    leftSiteId: $parent[0].id,
                    rightSiteId: .id
                };
                node($parent[0]);
                node(.));
            node($parent[0]))
    else    # right
        node({
                type: "break",
                side: "left",
                leftSiteId: $parent[0].id,
                rightSiteId: .id
            };
            node($parent[0]);
            node({
                    type: "break",
                    side: "right",
                    leftSiteId: .id,
                    rightSiteId: $parent[0].id
                };
                node(.);
                node($parent[0])))
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
        node($site)
    elif is_leaf then
        .data as $data | $site | make_subtree([ $data, "left" ])
    else
        if ([ .data, $site ] | bs_comparator($l; $sites)) > 0 then
            setpath(
                [ "left" ];
                .left as $left
                | if $left | is_leaf then
                      $site | make_subtree([ $left.data, "left" ])
                  else
                      $left | insert_site($site; $l; $sites)
                  end
            )
        else
            setpath(
                [ "right" ];
                .right as $right
                | if $right | is_leaf then
                      $site | make_subtree([ $right.data, "right" ])
                  else
                      $right | insert_site($site; $l; $sites)
                  end
            )
        end
    end
;

##
# Removes all occurrences of the $site from supplied BST and associated break points.
# @input root node of BST. Can be null for empty tree
# @param $siteId id of site to remove
# @output BST with removed site
def remove_site($siteId):
    if .data.type == "site" and .data.id == $siteId then
        null    # remove the site
    elif .data.type == "break" then
        setpath([ "left" ]; .left | remove_site($siteId))
        | setpath([ "right" ]; .right | remove_site($siteId))
        | if .left == null then
              .right
          elif .right == null then
              .left
          elif .data.leftSiteId == $siteId then
              if .left.data.type == "break" then
                  setpath([ "data", "leftSiteId" ]; .left.data.leftSiteId)
              else
                  setpath([ "data", "leftSiteId" ]; .left.data.id)
              end
          elif .data.rightSiteId == $siteId then
              if .right.data.type == "break" then
                  setpath([ "data", "rightSiteId" ]; .right.data.rightSiteId)
              else
                  setpath([ "data", "rightSiteId" ]; .right.data.id)
              end
          else
              .     # other breakpoint
          end
    else    # another site
        .
    end
;

##
# Finds circle events created by triplets of consecutive arcs (sites) on the beach line.
# Precondition beach line has at least three arcs.
# @input site[] beach line
# @output circleEvent[] array of calculated circle events
def find_circle_events:
    helpers::triplets
    | map(select(are_collinear | not))
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
            x: . | x,
            y: . | y
        })
;

##
# Recalculates circle events. Keeps site events as they are.
# @input voronoi voronoi object
# @output updated voronoi object
def recalculate_circle_events:
    ( .bstree | leaves ) as $beachline
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
    | leaves
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

def close_halfedges($circleEvent):
    $circleEvent.triplet as [ $p1, $p2, $p3 ]

    | setpath([ "halfedges", "\($p1.id)/\($p2.id)", "startPoint" ]; $circleEvent.center)
    | setpath([ "halfedges", "\($p2.id)/\($p1.id)", "endPoint" ]; $circleEvent.center)

    | setpath([ "halfedges", "\($p2.id)/\($p3.id)", "startPoint" ]; $circleEvent.center)
    | setpath([ "halfedges", "\($p3.id)/\($p2.id)", "endPoint" ]; $circleEvent.center)

    # Create two new halfedges between $p1 & $p3
    | setpath(
        [ "halfedges", "\($p1.id)/\($p3.id)" ];
        {
            id: "\($p1.id)/\($p3.id)",
            leftSiteId: $p1.id,
            rightSiteId: $p3.id,
            startPoint: null,
            endPoint: $circleEvent.center,
            startInfinite: false,
            endInfinite: false
        })
    | setpath(
        [ "halfedges", "\($p3.id)/\($p1.id)" ];
        {
            id: "\($p3.id)/\($p1.id)",
            leftSiteId: $p3.id,
            rightSiteId: $p1.id,
            startPoint: $circleEvent.center,
            endPoint: null,
            startInfinite: false,
            endInfinite: false
        })
;

##
# Handles the site event.
# @input voronoi voronoi object
# @param $site site event
# @output updated voronoi object
def handle_site_event($site):
    .sites as $sites
    | ( $site | y ) as $l
    | setpath([ "bstree" ]; .bstree | insert_site($site; $l; $sites))
    | recalculate_circle_events

    # Create a new edge
    | if .bstree | is_leaf | not then
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
    setpath([ "bstree" ]; .bstree | remove_site($circleEvent.siteId))
    | recalculate_circle_events

    # Close edges of disappeared site
    | close_halfedges($circleEvent)
;

##
# @input {halfedge} half edge
# @param $sites {{ [siteId: string]: site }} map of sites
# @param $boundaries {[ point, point ]} two points defining the bounding box
def close_halfedge($sites; $boundaries):
    . as $halfedge
    | $sites[.leftSiteId] as $leftSite
    | $sites[.rightSiteId] as $rightSite
    | ( $leftSite | x ) as $lsX
    | ( $leftSite | y ) as $lsY
    | ( $rightSite | x ) as $rsX
    | ( $rightSite | y ) as $rsY
    | ( $boundaries[0] | x ) as $minX
    | ( $boundaries[0] | y ) as $minY
    | ( $boundaries[1] | x ) as $maxX
    | ( $boundaries[1] | y ) as $maxY

    # Start by check special cases where edge is strictly horizontal or vertical
    | if $lsX == $rsX and $lsY > $rsY then
          # Strictly leftward
          [ $minX, ($lsY + $rsY) / 2 ]
      elif $lsX == $rsX and $lsY < $rsY then
          # Strictly rightward
          [ $maxX, ($lsY + $rsY) / 2 ]
      elif $lsX < $rsX and $lsY == $rsY then
          # Strictly upward
          [ ($lsX + $rsX) / 2, $minY ]
      elif $lsX > $rsX and $lsY == $rsY then
          # Strinctly downward
          [ ($lsX + $rsX) / 2, $maxY ]
      else
          ( [ $leftSite, $rightSite ] | midpoint ) as $midpoint
          | ( if equals(.startPoint; $midpoint) | not then
                  # Half edge can be traced between startPoint & $midpoint
                  [ .startPoint, $midpoint ] | to_gradient_intercept_form
              else
                  # Half edge is perpendicular to line segment between two sites
                  [ $leftSite, $rightSite ]
                  | to_gradient_intercept_form
                  | perpendicular($midpoint)
              end ) as $line_by_x

          | ( $line_by_x | form_by_y ) as $line_by_y

          | if $lsX < $rsX and $lsY > $rsY then
                # Left-upward
                ( $line_by_x | eval_line($minX) ) as $y
                | if $y >= $minY then
                      [ $minX, $y ]
                  else
                      ( $line_by_y | eval_line($minY) ) as $x
                      | [ $x, $minY ]
                  end
            elif $lsX < $rsX and $lsY < $rsY then
                # Right-upward
                ( $line_by_x | eval_line($maxX) ) as $y
                | if $y >= $minY then
                      [ $maxX, $y ]
                  else
                      ( $line_by_y | eval_line($minY) ) as $x
                      | [ $x, $minY ]
                  end
            elif $lsX > $rsX and $lsY < $rsY then
                # Right-downward
                ( $line_by_x | eval_line($maxX) ) as $y
                | if $y <= $maxY then
                      [ $maxX, $y ]
                  else
                      ( $line_by_y | eval_line($maxY) ) as $x
                      | [ $x, $maxY ]
                  end
            else
                # Left-downward
                ( $line_by_x | eval_line($minX) ) as $y
                | if $y <= $maxY then
                      [ $minX, $y ]
                  else
                      ( $line_by_y | eval_line($maxY) ) as $x
                      | [ $x, $maxY ]
                  end
            end
      end

    | . as $endPoint
    | $halfedge | setpath([ "endPoint" ]; $endPoint)

    # TODO: close unclosed startPoint
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

def create_cells:
    . as $voronoi
    | reduce (.sites | keys | .[]) as $siteId (
          $voronoi;

          # Select half edges of site
          ( .halfedges
            | values
            | map(select(.leftSiteId == $siteId))

            # TODO: move this reordering into close_cell
            # Order half edges by angle
            | sort_by(angle(.startPoint; .endPoint)) ) as $halfedges

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
    . as $cell
    | ( $boundaries[0] | x ) as $minX
    | ( $boundaries[0] | y ) as $minY
    | ( $boundaries[1] | x ) as $maxX
    | ( $boundaries[1] | y ) as $maxY

    | reduce $cell.halfedges[] as $halfedge (
          [null, null];
          if $halfedge.startInfinite then
              [ .[0], $halfedge.startPoint ]
          elif $halfedge.endInfinite then
              [ $halfedge.endPoint, .[1] ]
          else
              .
          end
      )

    | ( if (.[0] | x) == $minX then
            "down"
        elif (.[0] | y) == $maxY then
            "right"
        elif (.[0] | x) == $maxX then
            "up"
        else
            "left"
        end ) as $direction

    | {
          curr: .[0],
          dest: .[1],
          direction: $direction,
          halfedges: []
      }
    | (until(equals(.curr; .dest);
          ( .org | x ) as $x1
          | ( .org | y ) as $y1
          | ( .dest | x ) as $x2
          | ( .dest | y ) as $y2

          | (if .direction == "down" then
                if $y2 >= $y1 and $y2 <= $maxY then
                    .dest
                else
                    [ $minX, $maxY ]
                end
            elif .direction == "right" then
                if $x2 >= $x1 and $x2 <= $maxX then
                    .dest
                else
                    [ $maxX, $maxY ]
                end
            elif .direction == "up" then
                if $y2 <= $y1 and $y2 >= $minY then
                    .dest
                else
                    [ $maxX, $minY ]
                end
            else    # left
                if $x2 <= $x1 and $x2 >= $minX then
                    .dest
                else
                    [ $minX, $minY ]
                end
            end) as $next

          | {
                curr: $next,
                dest,
                direction: (if .direction == "down" then
                               "right"
                           elif .direction == "right" then
                               "up"
                           elif .direction == "up" then
                               "left"
                           else
                               "down"
                           end),
                halfedges: (.halfedges + [{ startPoint: .curr, endPoint: $next }])
            }
      ) | .halfedges) as $newHalfedges

    | $cell
    | setpath([ "halfedges" ]; (.halfedges + $newHalfedges) | sort_by(angle(.startPoint; .endPoint)))
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
# Executes Fortune's algorithm.
# @input array of site points
# @param $boundaries [ point, point ] two points defining rectangle delimiting space where voronoi
# must be calculated
def fortune($boundaries):

    # Create the initial state
    reduce .[] as $input (

        # Initial state
        {
            bstree: null,
            events: [],
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
            events: .events | enqueue($site),
            sites: .sites | setpath([ $site_id | tostring ]; $site),
            id_seed: ( $site_id + 1 )
        }
    )

    # Process event queue
    | until(.events | is_empty;
        . as $state     # store current state
        | .sites as $sites

        # Dequeue next event
        | [ .events | dequeue(y_comparator) ] as [ $event, $queue ]
        | ( $event | y ) as $l
        | setpath([ "events" ]; $queue)

        # Process site event
        | if $event.type == "site" then
              handle_site_event($event)
          else
              handle_circle_event($event)
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

    | close_half_infinite_edges($boundaries)

    | create_cells

    | close_unbound_cells($boundaries)

    # Output result
    | .cells
    | helpers::values
    | map(
          [[ (.site | x), (.site | y) ]]     # site
          +
          # Array of counterclockwise ordered vertices of polygon forming the cell of the site
          ( .halfedges | map([ (.startPoint | x), (.startPoint | y) ]) )
      )
;
