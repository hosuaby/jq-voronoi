module "parabola.test";

include "parabola";

def test_to_standard_form:

    # Given
    {
        focus: [ 2, 1 ],
        directrix: 3
    }

    # When
    | to_standard_form

    # Then
    | .[0] == -0.25 and .[1] == 2 and .[2] == 2
;

def test_intersections:

    # Given
    {
        focus: [ 2, 1 ],
        directrix: 3
    } as $p1
    | {
        focus: [ 1, 2.5 ],
        directrix: 3
    } as $p2

    # When
    | ( $p1 | to_standard_form
    #| debug
    ) as $sp1
    | ( $p2 | to_standard_form
    # | debug
    ) as $sp2

    # Then
    | intersections($sp1; $sp2)
;
