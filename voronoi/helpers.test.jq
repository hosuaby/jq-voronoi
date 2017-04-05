module "helpers.test";

import "helpers" as helpers;

def test_triplets:

    # Given
    [5, 7, 3, 0, 1, 5, 6]

    # When
    | helpers::triplets

    # Then
;

def test_triplets_tree_elements:

    # Given
    [5, 7, 3]

    # When
    | helpers::triplets

    # Then
;

def test_key_by:

    # Given
    [ 5, 8, 9, 15 ]

    # When
    | helpers::key_by("KEY_" + (. | tostring))

    # Then
;

def test_key_by_with_objects:

    # Given
    [ { id: "a", content: "Frodon" }, { id: "b", hobbit: "Bilbo" } ]

    # When
    | helpers::key_by(.id)

    # Then
;

def test_values:

    # Given
    {
        a: 10,
        b: 15
    }

    # When
    | helpers::values

    # Then
    | .[0] == 10 and .[1] == 15
;
