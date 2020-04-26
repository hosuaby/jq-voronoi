#!jq -f

import "spherical_voronoi" as sv;

##
# Calculates voronoi diagram on spherical surface from supplied array of sites.
# Example:
#       echo '[[1, 1.5], [1, 1], [1, 2.2]]' | ./voronoi-sphere.sh
#
# @input {sphericalPoint[]} array of points expressed in spherical coordinates [azimuth, zenith].
#                           0 <= azimuth < 2PI
#                           0 <= zenith <= PI
#
# @author hosuaby

sv::spherical_voronoi
