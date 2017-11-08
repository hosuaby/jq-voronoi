module "queue";

##
# Implementation of queue.
#
# type queue = any[];
#
# Queue is just a JSON array [].
# Queue can be used as priority queue if comparator is provided as parameter of dequeue function.
# Comparator is the function accepting tuple [ $firstElement, $secondElement ] and returning a
# negative number if $firstElement is strictly inferior, a positive number if $firstElement is
# strictly superior, and 0 if two elements are equal.
#
# @author hosuaby

##
# Checks if supplied queue is empty.
# @input {queue} queue
# @output {boolean} true if queue is empty, false if not
def is_empty:
    length == 0
;

##
# Adds $elem at the tail of supplied queue.
# @input {queue} queue
# @param $elem {any} element to add into the queue
# @output {queue} updated queue
def enqueue($elem):
    [ .[], $elem ]
;

##
# Add miltiple elements at the tail of supplied queue.
# @input {queue} queue
# @param $elems {any[]} elements to add into the queue
# @output {queue} updated queue
def enqueue_all($elems):
    . + $elems
;

##
# Removes element from the head of the queue. Returns removed element and rest of the queue (tail).
# @input {queue} queue
# @output $head {any} element removed from the head,
#         $tail {any[]} rest of the queue
def dequeue:
    if is_empty | not then
        .[0], .[1:length]
    else
        error("Queue must not be empty")
    end
;

##
# Removes element from the queue having highest priority according provided comparator function.
# @input {queue} queue
# @param comparator {filter} comparator function
# @output $head {any} element removed from the head,
#         $tail {any[]} rest of the queue
def dequeue(comparator):
    if is_empty | not then
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
