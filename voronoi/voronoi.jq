#!jq -f

include "fortune";

##
# @input array of points. First two points are diagram boundaries, the rest are sites
[ .[0], . [1] ] as $boundaries
| .[2:] as $sites
| $sites
| fortune($boundaries)
