module "queue.test";

include "queue";

def number_comparator:
    .[0] - .[1]
;

def test_is_empty_with_empty_queue:

    # Given
    []

    # When
    | is_empty

    # Then
    # queue is empty
;

def test_is_empty_with_non_empty_queue:

    # Given
    [ 1 ]

    # When
    | is_empty
    | not

    # Then
    # queue is non empty
;

def test_enqueue:

    # Given
    [ 1, 2, 3 ]

    # When
    | enqueue(6)

    # Then
    | length == 4 and .[0] == 1 and .[1] == 2 and .[2] == 3 and .[3] == 6
;


def test_dequeue:

    # Given
    [ 1, 2, 3 ]

    # When
    | [ dequeue ] as [ $head, $tail ]

    # Then
    | $head == 1 and ($tail | length == 2 )
;

def test_dequeue_with_comparator:

    # Given
    [ 5, 78, 15, 6, 3, 26, 88, 6 ]

    # When
    #| dequeue(number_comparator)

    | until(is_empty;
        [ . | dequeue(number_comparator) ] as [ $elem, $queue ]
        | ( $elem | debug )
        | ( $queue | debug )
        | $queue
    )

    # Then
;

def test_usecase:

    # Given
    [ 1, 2, 3, 5, 6, 8, 4 ]

    # When
    | [ ., [] ]
    | until (
        (.[0] | length == 0);

        . as [ $q, $out ]
        | $q | dequeue as [ $head, $tail ]
        | if $head % 2 == 1
          then
            [ $tail, ($out | enqueue($head)) ]
          else
            [ $tail | enqueue($head/2) | enqueue($head/2), $out ]
          end
      )
    | .[1]

    # Then
;



