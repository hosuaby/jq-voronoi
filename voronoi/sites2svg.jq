#!jq -rf

##
# Renders set of sites as SVG.
#
# @input {point[]} array of points. First two points are diagram boundaries, the rest are sites
# @output {string} set of sites rendered in SVG
#
# @author hosuaby

##
# Returns SVG representation of supplied site.
# @input {[ number, number ]} site coordinates
# @output {string} SVG circle representing a site
def site:
    "<circle cx=\"\(.[0])\" cy=\"\(.[1])\" r=\"3\" fill=\"red\" />"
;

##
# Start of script

[ .[0], . [1] ] as [[$minX, $minY], [$maxX, $maxY]]
| .[2:] as $sites
| ( $maxX - $minX ) as $width
| ( $maxY - $minY ) as $height
| $sites
| map(site)
| join("\n")

| "<?xml version=\"1.0\" standalone=\"no\"?>
<svg xmlns=\"http://www.w3.org/2000/svg\"
     version=\"1.1\"
     width=\"\($width)px\"
     height=\"\($height)px\"
     viewBox=\"\($minX) \($minY) \($maxX) \($maxY)\">
    <desc>jq-voronoi by hosuaby @ https://github.com/hosuaby</desc>
    \(.)
</svg>"
