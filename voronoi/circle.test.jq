module "circle.test";

import "circle" as circle;

def test_circle_center:

    # Given
    [ [2, 7], [3, 5], [7, 8] ]

    # When
    | circle::circle_center

    # Then
;

def test_from_triplet:

    # Given
    [ [2, 7], [3, 5], [7, 8] ]

    # When
    | circle::from_triplet

    # Then
;
