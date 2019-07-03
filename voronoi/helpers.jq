module "helpers";

##
# Module of miscellaneous functions.
#
# @author hosuaby

# Largest positive number on IEEE754 double-precision (64-bit)
def PLUS_INFINITY: 9007199254740992;

# Smallest negative number on IEEE754 double-precision (64-bit)
def MINUS_INFINITY: -9007199254740992;

# Infinitely small number
def EPSILON: 1e-9;

##
# Shortcut for expression if-then-else.
# @input {any} anything
# @param condition {filter} condition that input must respect
# @param likewise {filter} applied if input respects condition
# @param otherwise {filter} applied if input don't respects condition
# @output {any} anything
def if_else(condition; likewise; otherwise):
    if (condition) then
        likewise
    else
        otherwise
    end
;

##
# Returns absolute value of supplied number.
# Note: this method is needed because builtin fabs is not always available.
# @input {number} a number
# @output {number} absolute value of the number
def abs:
    if_else(. >= 0; .; -.)
;

##
# Returns sign of supplied number. Return 1 if number is positive, -1 if negative or 0 if it is
# zero.
# @input {number} number
# @output {number} sign of number
def sign:
    if . == 0 then
        0
    elif . < 0 then
        -1
    else
        1
    end
;

##
# Filters out empty strings, arrays and objects
# @input {any} anything
# @output {any | empty} outputs value from input if it was not empty
def filter_empty:
    if . == null then
        empty
    elif type == "array" or type == "object" or type == "string" then
        if_else(length > 0; .; empty)
    else
        .
    end
;

##
# Tests if difference between supplied number & $other number is less that EPSILON (numbers are very
# close).
# @input {number} a number
# @param $other {number} other number
# @output {boolean} true - two numbers are very close, false - numbers are far from each other
def is_close_to($other):
    (. - $other | abs) < EPSILON
;

##
# Approximates input value by $other value, if it's close enough.
# @input {number} value
# @param $other {number} other value
# @output {number} supplied number approximated by other
def approximate($other):
    if_else(is_close_to($other); $other; .)
;

##
# Multiplies all elements of supplied array.
# @input {number[]} numbers
# @output {number} result of multiplication of array elements
def multiply:
    reduce .[] as $n (1; . * $n)
;

##
# Produces array of bigrams (two successive elements) from supplied array.
# Precondition: supplied array must have at least two elements.
# Example:
#       Input: [5, 7, 3, 0, 1, 5, 6]
#       Output: [[5, 7], [7, 3], [3, 0], [0, 1], [1, 5], [5, 6]]
# @input {any[]} array
# @output {[any, any][]} array of bigrams
def bigrams:
    . as $array
    | if length > 1 then
          [ range(length - 1) | $array[. : .+2] ]
      else
          error("Array \(.) has less than 2 elements")
      end
;

##
# Produces array of trigrams (three successive elements) from supplied array.
# Precondition: supplied array must have at least three elements.
# Example:
#       Input: [5, 7, 3, 0, 1, 5, 6]
#       Output: [[5, 7, 3], [7, 3, 0], [3, 0, 1], [0, 1, 5], [1, 5, 6]]
# @input {any[]} array
# @output {[any, any, any][]} array of trigrams
def trigrams:
    . as $array
    | if length > 2 then
          [ range(length - 2) | $array[. : .+3] ]
      else
          error("Array \(.) has less than 3 elements")
      end
;

##
# Merges two arrays by combining elements with same indices.
# Example:
#       Input: [1, 2, 3] & [4, 5, 6]
#       Output: [[1, 4], [2, 5], [3, 6]]
# @input {any[]} this array
# @param $other {any[]} other array
# @output {any[]} zip of two arrays
def zip($other):
    . as $this
    | length as $l
    | [ range($l) ]
    | map([ $this[.], $other[.] | select(. != null) ])
    | [ .[], ($other[$l:] | map([.]) | .[]) ]
;

##
# Counts number of element of array that satisfy condition.
# @input {any[]} array
# @param condition {filter} condition that elements of array must respect
# @output {number} number of element of array that satisfy condition
def count(condition):
    map(if_else(condition; 1; 0))
    | add
    | if_else(. != null; .; 0)
;

##
# Rotates array left.
# Example:
#       Input: [1, 2, 3, 4, 5]
#       Output: [2, 3, 4, 5, 1]
# @input {any[]} array
# @output {any[]} array rotated left
def rotate_left:
    if_else(length > 0; [ .[1:][], .[0] ]; [])
;

##
# Add index to each element of input array.
# Example:
#       Input: ["one", "two", "three"]
#       Output: [[0, "one"], [1, "two"], [2, "three"]]
# @input {any[]} array
# @output {[number, any]} array of pairs index-element
def index:
    . as $elems
    | length as $l
    | [ range($l) ]
    | map([ ., $elems[.] ])
;

##
# Sets array element by index.
# @input {any[]} array
# @param $index {number} element index
# @param $elem {any} element to set
# @input {any[]} updated array
def set_by_index($index; $elem):
    [ .[:$index][], $elem, .[$index+1:][] ]
;

##
# Creates an object composed of keys from the results of running each element of supplied array
# through iteratte. The corresponding value of each key is the last element responsible for
# generating the key.
# @input {any[]} array of elements
# @param iteratee {filter} filter applied to each element to create a key
# @output object composed of elements of supplied array with associated keys
def key_by(iteratee):
    map({ key: iteratee, value: . }) | from_entries
;

##
# Merges series of adjacent elements which satisfy the given predicate using the merger function and
# returns a new array.
# @input {any[]} array of elements
# @param collapsible {filter} predicate to apply to the pair of adjacent elements of the input array
#                             which returns true for elements which are collapsible
# @param merger {filter} associative function to merge two adjacent elements for which collapsible
#                        predicate returned true. Note that it can be applied to the results if
#                        previous merges.
# @output {any[]} arrays where elements was collapsed
def collapse_by(collapsible; merger):
    reduce .[] as $elem (
        {
            output: [],
            lastKey: null,
            lastElem: null
        };

        if .lastKey != null then
            if ($elem | collapsible) == .lastKey then
                {
                    output,
                    lastKey,
                    lastElem: [.lastElem, $elem] | merger
                }
            else
                {
                    output: [.output[], .lastElem],
                    lastKey: $elem | collapsible,
                    lastElem: $elem
                }
            end
        else
            {
                output,
                lastKey: $elem | collapsible,
                lastElem: $elem
            }
        end
    )

    | [ .output[], if_else(.lastElem != null; .lastElem; empty) ]
;

##
# Creates an array of the own enumerable string keyed property values of supplied object.
# @input {object} object
# @output {object[]} array of values
def values:
    . as $obj
    | keys_unsorted
    | map($obj[.])
;

##
# Finds the first element of the array which satisfies provided condition. If no such element,
# returns null.
# @input {any[]} array
# @param condition {filter} condition that element must satisfy
# @output {[any, number] | null} pair of found element/index of element, null if no element
# satisfying condition was found
def find_first(condition):
    to_entries
    | map(select(.value | condition))
    | if_else(length > 0; [ .[0].value, .[0].key ]; null)
;

##
# For supplied array generates array of indexes starting from $n and ending at $n-1.
# Example:
#       Input: [5, 7, 3, 0, 1, 5, 6] | cyclic_indexes(3)
#       Output: [3, 4, 5, 6, 0, 1, 2]
# @input {any[]} array
# @param {number} $n start index
# @output {number[]} range of indexes
def cyclic_indexes($n):
    [range($n; length)] + [range($n)]
;

##
# For supplied array generates array of indexes starting from $from and ending at $to (inclusive).
# Example:
#       Input: [5, 7, 3, 0, 1, 5, 6] | cyclic_indexes(3, 2)
#       Output: [3, 4, 5, 6, 0, 1, 2]
# @input {any[]} array
# @param {number} $from start index
# @param {number} $to end index
# @output {number[]} range of indexes
def cyclic_indexes($from; $to):
    if $from <= $to then
        [range($from; $to+1)]
    else
        [range($from; length)] + [range($to+1)]
    end
;

##
# Returns values from supplied object associated with keys provided as array $keys. Supplied object
# can be object literal or JSON array. If no value associated with a key, method return null.
# Values are returned in the same order than provided keys.
# Example 1:
#       Input: { "a": 42, "b": "test", "c": ["one", "two"] } | extract(["a", "c"])
#       Output: [42, ["one", "two"]]
# Example 2:
#       Input: [5, 7, 3, 0, 1, 5, 6] | extract([1, 4, 3])
#       Output: [7, 1, 0]
# @input {object | any[]} object or array
# @param $keys {number[] | string[]} keys of fields to exctract
# @output {any[]} extracted values
def extract($keys):
    . as $input
    | $keys
    | map(try $input[.] catch null)
;

##
# Partitions input by defined condition. Returns two groups of input elements, those that satisfies
# condition and those that not satisfies.
# @input {any[]} array of elements
# @param condition {filter} condition that return boolean value to partition elements
# @output {[ any[], any[] ]} two groups: satisfying elements, and not satisfying
def partitioning_by(condition):
    reduce .[] as $elem (
        [[], []];

        if ($elem | condition) then
            [[.[0][], $elem], .[1]]
        else
            [.[0], [.[1][], $elem]]
        end
    )
;

##
# Returns an array with input value repeated $n times.
# @input {any} any value
# @param $n {number} number of times
# @output {any[]} array with $n values
def times($n):
    . as $val
    | [ range($n) ]
    | map($val)
;

##
# Sets $val in position $i of supplied array.
# @input {any[]} array
# @param $i {number} index
# @param $val {any} value to set
# @output {any[]} updated array
def set_by_index($i; $val):
    . as $array
    | length as $l

    | if $i < $l then
          [
              $array[:$i][],
              $val,
              $array[$i+1:][]
          ]
      else
          [
              $array[],
              ( null | times($i-$l) | .[] ),
              $val
          ]
      end
;