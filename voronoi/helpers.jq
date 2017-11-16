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
# Returns absolute value of supplied number.
# Note: this method is needed because builtin fabs is not always available.
# @input {number} a number
# @output {number} absolute value of the number
def abs:
    if . >= 0 then
        .
    else
        -.
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
# Creates an array of the own enumerable string keyed property values of supplied object.
# @input {object} object
# @output {object[]} array of values
def values:
    . as $obj
    | keys_unsorted
    | map($obj[.])
;

##
# Finds the first element of the array which satisfies provided condition cond. If no such element,
# returns null.
# @input {any[]} array
# @param cond {filter} condition that element must satisfy
# @output {[any, number] | null} pair of found element/index of element, null if no element
# satisfying condition was found
def find_first(cond):
    to_entries
    | map(select(.value | cond))
    | if length > 0 then
          [ .[0].value, .[0].key ]
      else
          null
      end
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
