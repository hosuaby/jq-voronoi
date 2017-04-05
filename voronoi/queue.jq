module "queue";

##
# Queue is just a JSON array [].
# Queue can be used as priority queue if comparator is provided as parameter of dequeue function.
# Comparator is the function accepting tuple [ $firstElement, $secondElement ] and returning a
# negative number (generally -1) if $firstElement is strictly inferior, a positive number
# (generally +1) if $firstElement is strictly superior, and 0 if two elements are equal.
#
# @author hosuaby

##
# Checks if supplied queue is empty.
# @input queue
# @output true if queue is empty, false if not
def is_empty:
    length == 0
;

##
# Checks if supplied queue is empty.
# @input queue
# @output true if queue is empty, false if not
def is_not_empty:
    is_empty | not
;

##
# Adds $elem at the tail of supplied queue.
# @input queue
# @param $elem element to add into the queue
# @output updated queue
def enqueue($elem):
    [ .[], $elem ]
;

##
# Removes element from the head of the queue. Returns removed element and rest of the queue (tail).
# @input queue
# @output $head, $tail
def dequeue:
    if is_not_empty then
        .[0], .[1:length]
    else
        error("Queue must not be empty")
    end
;

##
# Removes element from the queue having highest priority according provided comparator function.
# @param comparator comparator function
# @input queue
# @output removed element, rest of the queue
def dequeue(comparator):
    if is_not_empty then
        . as $queue
        | length as $l

        # Find minimum
        | foreach range(0; $l) as $i (    # for i in jq
            [ .[0], 0 ];

            .[0] as $min
            | $queue[$i] as $elem
            | if [ $elem, $min ] | comparator < 0 then
                [ $elem, $i]
            else
                .
            end;

            if $i == $l - 1 then
                .
            else
                empty
            end
        )

        # Remove minimum from queue
        | . as [ $min, $min_index ]
        | $min, [ $queue[:$min_index][], $queue[$min_index+1:][] ]
    else
        error("Queue must not be empty")
    end
;
