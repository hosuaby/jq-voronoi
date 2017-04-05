module "point.test";

include "point";

def test_x:

    # Given
    [ 3, 5 ]

    # When
    | x

    # Then
    | . == 3
;

def test_y:

    # Given
    [ 3, 5 ]

    # When
    | y

    # Then
    | . == 5
;

def test_equals_same_point:

    # Given
    [3, 5] as $a
    | [3, 5] as $b

    # When
    | equals($a; $b)

    # Then
    # IS TRUE
;

def test_equals_different_points:

    # Given
    [3, 5] as $a
    | [7, 1] as $b

    # When
    | equals($a; $b)

    # Then
    | not
;

def test_distance_euclidean:

    # Given
    [[1, 2], [1, 4]]

    # When
    | distance_euclidean(.[0]; .[1])

    # Then
    | . == 2
;

def test_angle:

    # Given
    [[1, 2], [1, 4]]

    # When
    | angle(.[0]; .[1])

    # Then
    | . == 1.5707963267948966   # PI / 2
;

# TODO: code this test
def test_are_collinear:
    .
;

def test_midpoint:

    # Given
    [ [-1, 2], [3, -6] ]

    # When
    | point::midpoint

    # Then
    | .[0] == 1 and .[1] == -2
;
