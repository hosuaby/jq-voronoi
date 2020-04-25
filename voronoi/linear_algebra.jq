module "linear_algebra";

include "helpers";

##
# Module for general linear algebra functions.
#
# type column = number[]
# type matrix = column[]
# type vector(n) = [number[n]]
#
# @author hosuaby

##
# Creates an identity matrix of size $n.
# @input {void} nothing
# @param $n {number} matrix size (n x n)
# @output {matrix} identity matrix
# @see https://en.wikipedia.org/wiki/Identity_matrix
def identity($n):
    [ range($n) ]
    | map(
          . as $i
          | 0
          | times($n)
          | set_by_index($i; 1)
      )
;

##
# Return number of row of supplied matrix.
# @input {matrix} matrix
# @output {number} number of matrix's rows
def nb_rows:
    map(length)
    | max
;

##
# Returns matrix with values grouped by rows instead of columns.
# @input {matrix} matrix
# @output {number[]} rows of matrix
def rows:
    . as $matrix
    | nb_rows as $nbRows
    | [ range($nbRows) ]
    | map(
          . as $i
          | $matrix
          | map(.[$i])
          | map(select(. != null))
      )
;

##
# Multiplies two matrices. Supplied matrix is on the left and parameter matrix on the right.
# @input {matrix} left matrix
# @param $right {matrix} right matrix
# @output {matrix} result of matrix multiplication
# @see https://www.mathsisfun.com/algebra/matrix-multiplying.html
def multiply_with_matrix($right):
    . as $left

    | if length == ($right | nb_rows) then
          $left
          | rows as $rows
          | $right
          | map(
                . as $column
                | $rows
                | map(
                      zip($column)
                      | map(multiply)
                      | add
                  )
            )
      else
          error("The number of columns of the 1st matrix must equal the number of rows of the 2nd matrix")
      end
;

##
# Multiplies matrix by scalar.
# @input {matrix} matrix
# @param {scalar} scalar
# @output {matrix} result of multiplication
def multiply_with_scalar($scalar):
    map(map(. * $scalar))
;

##
# Adds two matrices.
# @input {matrix} left matrix
# @param $right {matrix} right matrix
# @output {matrix} result of matrix sum
def add_matrix($right):
    . as $left

    | length as $nbLeftColumns
    | nb_rows as $nbLeftRows

    | $right
    | length as $nbRightColumns
    | nb_rows as $nbRightRows

    | if $nbLeftColumns == $nbRightColumns and $nbLeftRows == $nbRightRows then
          $left
          | zip($right)
          | map(
                . as [ $a, $b ]
                | $a
                | zip($b)
                | map(add)
            )
      else
          error("Added matrices must have same dimensions")
      end
;

##
# Calculates euclidean norm of vector.
# @input {vector} vector
# @output {number} euclidean norm
def norm:
    .[0]
    | map(. * .)
    | add
    | sqrt
;

def _determinant2:
    . as [ [$a, $c], [$b, $d] ]
    | $a * $d - $b * $c
;

def _determinant3:
    . as [ [$a, $d, $g], [$b, $e, $h], [$c, $f, $i] ]

    | [ [$e, $h], [$f, $i] ]
    | _determinant2
    | ( . * $a ) as $first

    | [ [$d, $g], [$f, $i] ]
    | _determinant2
    | ( . * $b ) as $second

    | [ [$d, $g], [$e, $h] ]
    | _determinant2
    | ( . * $c ) as $third

    | $first - $second + $third
;

##
# Calculates determinant of two- or three- dimensional matrix.
# @input {matrix} matrix
# @output {number} determinant of matrix
# @see https://towardsdatascience.com/beginners-introduction-to-matrices-part-ii-42b86e791b8b
def determinant:
    if length == 2 then
        _determinant2
    elif length == 3 then
        _determinant3
    else
        error("Cannot calculate determinant of high dimensional matrices")
    end
;
