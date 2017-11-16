module "bstree";

##
# Implementation of Binary Search Tree.
#
# type node<T> = {
#     data: T,         // data stored in the node
#     left: node<T>,   // left node, null if leaf node
#     right: node<T>   // right node, null if leaf node
# }
#
# Operations "insert" & "delete" requires comparator function as parameter filter.
# Comparator is the function accepting tuple [ $firstElement, $secondElement ] and returning a
# negative number (generally -1) if $firstElement is strictly inferior, a positive number
# (generally +1) if $firstElement is strictly superior, and 0 if two elements are equal.
#
# @author hosuaby

##
# Creates a leaf node.
# @input {any} any input
# @param data {filter} filter producing node data from input
# @output {node<T>} leaf node
def node(data):
    {
        data: data,
        left: null,
        right: null
    }
;

##
# Creates a node.
# @input {any} any input
# @param data {filter} filter producing node data from input
# @param left {filter} filter producing left child from input
# @param right {filter} filter producing right child from input
# @output {node<T>} node
def node(data; left; right):
    {
        data: data,
        left: left,
        right: right
    }
;

##
# Testes if supplied node is a leaf.
# @input {node<T>} node
# @output {boolean} true if node is a leaf, false if not
def is_leaf:
    .left == null and .right == null
;

##
# Returns value of the first (most left) node of supplied tree.
# @input {node<T>} node
# @output {T} value of the first node
def first:
    last(recurse(.left)) | .data
;

##
# Returns value of the last (most right) node of supplied tree.
# @input {node<T>} node
# @output {T} value of the last node
def last:
    last(recurse(.right)) | .data
;

##
# Returns data of all leaves of supplied BST in order from left to right.
# @input {node<T> | null} root node of BST. Can be null for empty tree
# @output {T[]} array of data of all leaf nodes
def leaves:
    if . == null then
        []
    elif is_leaf then
        [ .data ]
    else
        ( .left | leaves ) + ( .right | leaves )
    end
;

##
# Calculates height (maximum number of levels) of supplied BST.
# @input {node<T> | null} root node of BST. Can be null for empty tree
# @output {number} height of BST
def height:
    if . == null then
        0
    elif is_leaf then
        1
    else
        [ (.left | height), (.right | height) ]
        | max
        | . + 1
    end
;

##
# Rotates BST left.
# @input {node<T>} root node of BST
# @output {node<T>} rotated left BST
# @see https://en.wikipedia.org/wiki/Tree_rotation
def rotate_left:
    node(.right.data;
        node(.data;
            .left;
            .right.left);
        .right.right)
;

##
# Rotates BST right.
# @input {node<T>} root node of BST
# @output {node<T>} rotated right BST
# @see https://en.wikipedia.org/wiki/Tree_rotation
def rotate_right:
    node(.left.data;
        .left.left;
        node(.data;
            .left.right;
            .right))
;

##
# Rebalances supplied BST.
# @input {node<T> | null} root node of BST. Can be null for empty tree
# @output {node<T> | null} rebalanced BST
def rebalance:
    if . == null or is_leaf then
        .
    else
        # First rebalance children
        setpath([ "left" ]; .left | rebalance)
        | setpath([ "right" ]; .right | rebalance)

        # Check if this tree also must be rebalanced
        | ( .left | height ) as $lh
        | ( .right | height ) as $rh
        | ( $lh - $rh ) as $diff

        | if $diff > 1 then
              # Need rotate right
              rotate_right
          elif $diff < -1 then
              # Need rotate left
              rotate_left
          else
              # No need rotate
              .
          end
    end
;
