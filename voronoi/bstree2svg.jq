#!jq -rf

import "point" as point;
import "bstree" as bstree;

##
# Tool for visualization of Binary-Search Tree used by fortune module as SVG.
# This script is for debugging purpose.
#
# type site = point & {
#     type: "site",
#     id: string        // site id
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
# type bstree = node<node_data>;
#
# @input {bstree} a Binary-Search Tree
# @output {string} SVG representation of the tree
#
# @author hosuaby

def CELL_SIZE: 60;
def CIRCLE_RADIUS: 26;

def LINE_STYLE: "stroke:black; stroke-width:2";

def BREAK_CIRCLE_STYLE: "stroke:#0055d4; fill:#5599ff";
def BREAK_ID_STYLE: "text-anchor:middle; font-family:sans-serif; font-size:18; fill:#ffffff";
def BREAK_SIDE_STYLE: "font-family:sans-serif; font-weight:bold; font-size:12; fill:#ff0000";

def SITE_CIRCLE_STYLE: "stroke:#d4aa00; fill:#ffcc00";
def SITE_ID_STYLE: "text-anchor:middle; font-family:sans-serif; font-size:18; fill:#ffffff";
def SITE_POINT_STYLE: "text-anchor:middle; font-family:sans-serif; font-size:8; fill:#000000";

##
# Draws a line between $from & $to points.
# @input {void} nothing
# @param $from {point} origin point
# @param $to {point} destination point
# @output {string} svg line between two points
def line($from; $to):
    ( $from | [ point::x, point::y ] ) as [ $x1, $y1 ]
    | ( $to | [ point::x, point::y ] ) as [ $x2, $y2 ]

    | "<line x1=\"\($x1)\"
             y1=\"\($y1)\"
             x2=\"\($x2)\"
             y2=\"\($y2)\"
             style=\"\(LINE_STYLE)\" />"
;

##
# Draws a supplied breakpoint as SVG circle.
# @input {breakpoint} breakpoint
# @param $center {point} center of breakpoint circle
# @param $parent {point | null} center of parent breakpoint circle, can be null
# @output $line {string} line from parent to current breakpoint
#         $circle {string} breakpoint rendered as SVG circle
def render_break($center; $parent):
    "\(.leftSiteId)/\(.rightSiteId)" as $id
    | ( if .side == "left" then
            "L"
        else
            "R"
        end ) as $side
    | ( $center | [ point::x, point::y ] ) as [ $x, $y ]
    | ( CELL_SIZE / 2 ) as $halfSize
    | ( $x - $halfSize ) as $translateX
    | ( $y - $halfSize ) as $translateY

    | ( if $parent != null then
            line($parent; $center)
        else
            ""
        end ) as $line

    | "<g transform=\"translate(\($translateX) \($translateY))\">
           <circle cx=\"\($halfSize)\"
                   cy=\"\($halfSize)\"
                   r=\"\(CIRCLE_RADIUS)\"
                   style=\"\(BREAK_CIRCLE_STYLE)\" />
           <text x=\"\($halfSize)\" y=\"36\" style=\"\(BREAK_ID_STYLE)\">\($id)</text>
           <text x=\"38\" y=\"14\" style=\"\(BREAK_SIDE_STYLE)\">\($side)</text>
       </g>" as $circle

    | $line, $circle
;

##
# Draws a supplied site as SVG circle.
# @input {site} site
# @param $center {point} center of site circle
# @param $parent {point} center of parent breakpoint circle
# @output $line {string} line from parent to current breakpoint
#         $circle {string} site rendered as SVG circle
def render_site($center; $parent):
    ( $center | [ point::x, point::y ] ) as [ $x, $y ]
    | ( CELL_SIZE / 2 ) as $halfSize
    | ( $x - $halfSize ) as $translateX
    | ( $y - $halfSize ) as $translateY

    | ( line($parent; $center) ) as $line

    | "<g transform=\"translate(\($translateX) \($translateY))\">
           <circle cx=\"\($halfSize)\"
                   cy=\"\($halfSize)\"
                   r=\"\(CIRCLE_RADIUS)\"
                   style=\"\(SITE_CIRCLE_STYLE)\" />
           <text x=\"\($halfSize)\" y=\"36\" style=\"\(SITE_ID_STYLE)\">\(.id)</text>
           <text x=\"\($halfSize)\" y=\"46\" style=\"\(SITE_POINT_STYLE)\">[\(.x),\(.y)]</text>
       </g>" as $circle

    | $line, $circle
;

##
# Returns a stream of SVG elements (lines and circles) that together makes SVG representation of the
# tree.
# @input {bstree} a Binary-Search Tree
# @param $layer {number} layer of currently drawn node:
#        0 - for a node root of BST, 1 - for direct children of the root, 2 - for grand-children ...
# @param $position {number} position of the current node in layer. 1 - for the left-most node
# @param $parent {point | null} center of the parent breakpoint node. Can be null
# @param $canvasWidth {number} width of SVG canvas
def render_tree($layer; $position; $parent; $canvasWidth):
    ( pow(2; $layer) ) as $itemsInLayer
    | ( $canvasWidth / $itemsInLayer ) as $spaceByItem
    | ( ($position - 1) * $spaceByItem ) as $leftBorder
    | ( $leftBorder + $spaceByItem ) as $rightBorder
    | ( ($leftBorder + $rightBorder) / 2 ) as $x
    | ( $layer * CELL_SIZE + (CELL_SIZE / 2)) as $y

    | [$x, $y] as $point

    | if . == null then
          [ "" ]
      elif bstree::is_leaf then
          [ .data | render_site($point; $parent) ]
      else
          [ .data | render_break($point; $parent) ]
          + ( .left | render_tree($layer + 1; $position * 2 - 1; $point; $canvasWidth) )
          + ( .right | render_tree($layer + 1; $position * 2; $point; $canvasWidth) )
      end
;

##
# Start of script

bstree::height as $treeHeight
| ( pow(2; $treeHeight - 1) ) as $treeWidth
| ( $treeWidth * CELL_SIZE ) as $svgWidth
| ( $treeHeight * CELL_SIZE ) as $svgHeight

| render_tree(0; 1; null; $svgWidth)
| sort
| reverse
| . as $elems

| "<?xml version=\"1.0\" standalone=\"no\"?>
<svg xmlns=\"http://www.w3.org/2000/svg\"
     version=\"1.1\"
     width=\"\($svgWidth)px\"
     height=\"\($svgHeight)px\"
     viewBox=\"0 0 \($svgWidth) \($svgHeight)\">
     \($elems | join("\n"))
</svg>"
