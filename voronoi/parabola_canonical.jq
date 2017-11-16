#!jq -fr

import "parabola" as parabola;

##
# Usage:
#     echo '[1, 2, 3]' | ./parabola_canonical.jq
# @input [ focus.x, focus.y, directrix ]

{
    focus: [ .[0], .[1] ],
    directrix: .[2]
}
| parabola::to_standard_form
| "\(.[0]) * (x - \(.[1]))^2 + \(.[2])"
