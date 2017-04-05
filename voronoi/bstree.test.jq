module "bsbtree.test";

include "bstree";

def number_comparator:
    .[0] - .[1]
;

def test_is_leaf_with_leaf:

    # Given
    {
        data: 42,
        left: null,
        right: null
    }

    # When
    | is_leaf

    # Then
    # IS LEAF
;

def test_is_leaf_with_not_leaf:

    # Given
    {
        data: 42,
        left: {
            data: 5,
            left: null,
            right: null
        },
        right: {
            data: 88,
            left: null,
            right: null
        }
    }

    # When
    | is_leaf

    # Then
    | not
;

def test_next_empty_tree:

    # Given
    null

    # When
    | next(10; number_comparator)

    # Then
    | . == null
;

def test_next_1:

    # Given
    node(7;
        node(3);
        node(18;
            node(10;
                node(8);
                node(11));
            node(22;
                null;
                node(26))))

    # When
    | next(10; number_comparator)

    # Then
    | . == 11
;

def test_next_2:

    # Given
    node(7;
        node(3);
        node(18;
            node(10;
                node(8);
                node(11));
            node(22;
                null;
                node(26))))

    # When
    | next(11; number_comparator)

    # Then
    | . == 18
;

def test_next_for_last_node:

    # Given
    node(7;
        node(3);
        node(18;
            node(10;
                node(8);
                node(11));
            node(22;
                null;
                node(26))))

    # When
    | next(26; number_comparator)

    # Then
    | . == null
;

def test_prec_empty_tree:

    # Given
    null

    # When
    | prec(10; number_comparator)

    # Then
    | . == null
;

def test_prec_1:

    # Given
    node(7;
        node(3);
        node(18;
            node(10;
                node(8);
                node(11));
            node(22;
                null;
                node(26))))

    # When
    | prec(10; number_comparator)

    # Then
    | . == 8
;

def test_prec_2:

    # Given
    node(7;
        node(3);
        node(18;
            node(10;
                node(8);
                node(11));
            node(22;
                null;
                node(26))))

    # When
    | prec(22; number_comparator)

    # Then
    | . == 18
;

def test_prec_first_node:

    # Given
    node(7;
        node(3);
        node(18;
            node(10;
                node(8);
                node(11));
            node(22;
                null;
                node(26))))

    # When
    | prec(3; number_comparator)

    # Then
    | . == null
;

def test_leaves:

    # Given
    node(7;
        node(3);
        node(18;
            node(10;
                node(8);
                node(11));
            node(22;
                null;
                node(26))))

    # When
    | leaves

    # Then
    | .[0] == 3 and .[1] == 8 and .[2] == 11 and .[3] == 26
;

def test_first:

    # Given
    node(7;
        node(3);
        node(18;
            node(10;
                node(8);
                node(11));
            node(22;
                null;
                node(26))))

    # When
    | first

    # Then
    | . == 3
;

def test_last:

    # Given
    node(7;
        node(3);
        node(18;
            node(10;
                node(8);
                node(11));
            node(22;
                null;
                node(26))))

    # When
    | last

    # Then
    | . == 26
;

def test_parent_1:

    # Given
    node(7;
        node(3);
        node(18;
            node(10;
                node(8);
                node(11));
            node(22;
                null;
                node(26))))

    # When
    | parent(10; number_comparator)

    # Then
    | .[0] == 18 and .[1] == "left"
;

def test_parent_2:

    # Given
    node(7;
        node(3);
        node(18;
            node(10;
                node(8);
                node(11));
            node(22;
                null;
                node(26))))

    # When
    | parent(18; number_comparator)

    # Then
    | .[0] == 7 and .[1] == "right"
;

def test_parent_root:

    # Given
    node(7;
        node(3);
        node(18;
            node(10;
                node(8);
                node(11));
            node(22;
                null;
                node(26))))

    # When
    | parent(7; number_comparator)

    # Then
    | .[0] == null and .[1] == null
;

def test_parent_data_not_present:

    # Given
    node(7;
        node(3);
        node(18;
            node(10;
                node(8);
                node(11));
            node(22;
                null;
                node(26))))

    # When
    | parent(4; number_comparator)

    # Then
    # EXCEPTION THROWN
;

def test_find_in_tree:

    # Given
    node(7;
        node(3);
        node(18;
            node(10;
                node(8);
                node(11));
            node(22;
                null;
                node(26))))

    # When
    | find(20; number_comparator)

    # Then
    | .[0] == 22 and .[1] == "left"
;

def test_insert:

    # Given
    null

    # When
    | insert(7; number_comparator)
    | insert(42; number_comparator)
    | insert(5; number_comparator)
    | insert(13; number_comparator)

    # Then
;

def test_delete_leaf:

    # Given
        node(7;
            node(3);
            node(18;
                node(10;
                    node(8);
                    node(11));
                node(22;
                    null;
                    node(26))))

    # When
    | delete(8; number_comparator)

    # Then
;

def test_delete_node_with_one_child:

    # Given
    node(7;
        node(3);
        node(18;
            node(10;
                node(8);
                node(11));
            node(22;
                null;
                node(26))))

    # When
    | delete(22; number_comparator)

    # Then
;

def test_delete_node_with_two_children:

    # Given
        node(7;
            node(3);
            node(18;
                node(10;
                    node(8);
                    node(11));
                node(22;
                    null;
                    node(26))))

    # When
    | delete(18; number_comparator)

    # Then
;

def test_rotate_left:

    # Given
    node("A";
        node("X");
        node("B";
            node("Y");
            node("Z")))

    # When
    | rotate_left

    # Then
;

def test_rotate_right:

    # Given
    node("B";
        node("A";
            node("X");
            node("Y"));
        node("Z"))

    # When
    | rotate_right

    # Then
;
