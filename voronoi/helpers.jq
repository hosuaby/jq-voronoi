module "helpers";

##
# Module of miscellaneous functions.
#
# @author hosuaby

##
# Produces array of triplets (three successive elements) from supplied array.
# Precondition: supplied array must have at least three elements.
# Example:
#       Input: [5, 7, 3, 0, 1, 5, 6] | triplets
#       Output: [[5, 7, 3], [7, 3, 0], [3, 0, 1], [0, 1, 5], [1, 5, 6]]
# @input array
# @output array of triplets
def triplets:
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
# @input array of elements
# @param iteratee filter applied to each element to create a key
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
