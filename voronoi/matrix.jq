module "matrix";

import "helpers" as helpers;

##
# Module for working with matrices.
#
# @author hosuaby

##
# Creates identity matrix of size n x n;
# @input nothing
# @param $n {number} size of matrix
# @output {number[][]} identity matrix of size n x n
def identity($n):
    [ range($n)
      | . as $i
      | [ ( 0 | helpers::times($i) ), 1, ( 0 | helpers::times($n-$i-1) ) ]
    ]
;

##
# Concatenates matrix A provided as input with matrix $B.
# Concatenation is a process of combining of two matrices of same height into a new one as follows:
#    |1  2  3|   |10  11|   |1  2  3  10  11|
#    |4  5  6| + |12  13| = |4  5  6  12  13|
#    |7  8  9|   |14  15|   |7  8  9  14  15|
# @input {number[][]} matrix A
# @param $B {number[][]} matrix B
# @ouput {number[][]} result of concatenation
def concat($B):
    . as $A
    | length as $height
    | if $height == ($B | length) then
          reduce range($height) as $i (
              [];
              . + [ $A[$i] + $B[$i] ]
          )
      else
          error("Matrices for concatenation have different heights")
      end
;

##
# Multiplies supplied as input matrix A by matrix provided as parameter B.
# The number of columns in first matrix must be equal to the number of rows in second matrix.
# @input matrix {number[][]} matrix
# @param $B {number[][]} another matrix
# @output {number[][]} result of matrix multiplication
def multiply($B):

    ##
    # Multiplies one row and one column
    # @input {[ number[], number[] ]} pair of column and row
    def _mult:
        . as [ $row, $col ]
        | ( [ range($row | length) ] ) as $indices
        | reduce $indices[] as $i (0; . + $col[$i] * $row[$i])
    ;

    . as $A
    | length as $n      # result matrix will be of size n x n
    | ( $B | transpose ) as $transposed
    | [ $A, $transposed ]
    | [ combinations ]
    | map(_mult)
    | {
          head: [],
          tail: .
      }
    | until((.tail | length) == 0;
          {
              head: ( .head + [.tail[:$n]] ),
              tail: .tail[$n:]
          }
      )
    | .head
;
