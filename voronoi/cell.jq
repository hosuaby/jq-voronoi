module "cell";

include "point";

##
# type cell = {
#     site: point,              // site object associated with this cell
#     halfedges: halfedge[]     // array of halfedges, ordered counterclockwise, defining the polygon for this cell
# }
#
# @author hosuaby

##
# Computes bounding box of suplied cell.
# type bbox = {
#     x: number,        // x coordinate of upper left corner of the box
#     y: number,        // y coordinate of upper left corner of the box
#     width: number,    // width of the box
#     height: number    // height of the box
# }
def bbox:
    [ .halfedges[] | get_startpoint ]
    | {
        x: ( x | min )
        y: ( y | min )
        width: ( x | max )
        height: ( y | max )
    }
;