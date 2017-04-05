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
# @input any
# @param data filter producing node data from input
# @output leaf node
def node(data):
    {
        data: data,
        left: null,
        right: null
    }
;

##
# Creates a node.
# @input any
# @param data filter producing node data from input
# @param left filter producing left child from input
# @param right filter producing right child from input
# @output leaf node
def node(data; left; right):
    {
        data: data,
        left: left,
        right: right
    }
;

##
# Testes if supplied node is a leaf.
# @input node
# @output true if node is a leaf, false if not
def is_leaf:
    .left == null and .right == null
;

##
# Testes if supplied tree is empty.
# @input node
# @output true if tree is empty, false if not
def is_empty:
    length == 0
;

##
# Returns the data of node, next the node containing provided $data. Returns null if node with $data
# is a last node of the tree or tree is empty.
# @input root node of BST. Can be null for empty tree
# @param $data data to find
# @param comparator comparator function used to find $data
# @output data stored in node next to the node with $data
def next($data; comparator):
    if . == null then
        null
    else
        ( [ .data, $data ] | comparator ) as $compare2this
        | if $compare2this == 0 then
              # Node with $data is current node, next will be immediately right
              if .right != null then
                  .right.data
              else
                  null
              end
          elif $compare2this > 0 then
              # Node with $data is somewhere on the left of current node
              ( .left | next($data; comparator) ) as $next_on_left
              | if $next_on_left != null then
                    $next_on_left
                else
                    # Current node is the next for node with $data
                    .data
                end
          else
              # Node with $data is on the right
              .right | next($data; comparator)
          end
    end
;

##
# Returns the data of node, precedent the node containing provided $data. Returns null if node with
# $data is a first node of the tree or tree is empty.
# @input root node of BST. Can be null for empty tree
# @param $data data to find
# @param comparator comparator function used to find $data
# @output data stored in node precedent to the node with $data
def prec($data; comparator):
    if . == null then
        null
    else
        ( [ .data, $data ] | comparator ) as $compare2this
        | if $compare2this == 0 then
              # Node with $data is current node, precedent will be immediately left
              if .left != null then
                  .left.data
              else
                  null
              end
          elif $compare2this > 0 then
              # Node with $data is on the left
              .left | prec($data; comparator)
          else
              # Node with $data is somewhere on the right of current node
              ( .right | prec($data; comparator) ) as $prec_on_right
              | if $prec_on_right != null then
                    $prec_on_right
                else
                    # Current node is the precedent for node with $data
                    .data
                end
          end
    end
;

##
# Returns data of all leaves of supplied BST in order from left to right.
# @input root node of BST. Can be null for empty tree
# @output array of data of all leaf nodes
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
# Returns value of the "first" (min) node of supplied tree.
# @input node
# @output value of the "first" node
def first:
    last(recurse(.left)) | .data
;

##
# Returns value of the "last" (max) node of supplied tree.
# @input node
# @output value of the "last" node
def last:
    last(recurse(.right)) | .data
;

##
# Finds direct parent of node with provided $data. Returns found parent node with indicator "left"
# or "right" that tells if a node with $data is left or right child of its parent.
# Note: $data must be present within BST. If you need to find where insert node that doesn't exist
# yet use method bstree::find.
# Special returns:
#   - [ null, null ] when BST is empty
# @input root node of BST. Can be null for empty tree
# @param $data data to find
# @param comparator comparator function
# @output [ object | null, "left" | "right" | null ] data of the parent node with indicator telling
# where a new node will be inserted
# @throws error if node with $data is not present in the tree
def parent($data; comparator):
    if . == null then
        [ null, null ]
    else
        ( [ .data, $data ] | comparator ) as $res
        | if $res == 0 then
              [ null, null ]
          elif $res > 0 and .left.data != null then
              ( [ .left.data, $data ] | comparator ) as $res
              | if $res == 0 then
                    [ .data, "left" ]
                else
                    .left | parent($data; comparator)
                end
          elif .right.data != null then
              ( [ .right.data, $data ] | comparator ) as $res
              | if $res == 0 then
                    [ .data, "right" ]
                else
                    .right | parent($data; comparator)
                end
          else
              error("Node with data = '\($data)' is not present in the tree")
          end
    end
;

##
# Finds the node of the tree that will become parent of node with supplied $data when it will be
# inserted. Returns found node with indicator "left" or "right" that tells if a new node will be
# left of right child.y
# Special returns:
#   - [ null, "right" ] when data is inserted in the empty tree
# @input root node of BST. Can be null for empty tree
# @param $data data to insert
# @param comparator comparator function
# @output [ object | null, "left" | "right" ] data of the node that will be parent of inserted node
# with indicator telling where a new node will be inserted
def find($data; comparator):
    if . == null then
        [ null, "right" ]
    else
        ( [ .data, $data ] | comparator ) as $res
        | if $res > 0 then
              if .left == null then
                  [ .data, "left" ]
              else
                  .left | find($data; comparator)
              end
          else
              if .right == null then
                  [ .data, "right" ]
              else
                  .right | find($data; comparator)
              end
          end
    end
;

##
# Inserts a new node with provided data into the tree supplied as input. Insertion uses comparator
# function.
#
# Example:
#   insert(42, .[0] - .[1])
#
# @input root node of BST. Can be null for empty tree
# @param $data data to insert
# @param comparator comparator function
# @output modified tree
def insert($data; comparator):
    if . == null then
        node($data)
    else
        if ([ .data, $data ] | comparator) > 0
        then
            setpath([ "left" ]; .left | insert($data; comparator))
        else
            setpath([ "right" ]; .right | insert($data; comparator))
        end
    end
;

##
# Inserts the whole subtree. Uses comparator function on the root on inserted subtree to find the
# right parent.
# @input root node of BST. Can be null for empty tree
# @param $subtree inserted subtree
# @param comparator comparator function
# @output modified tree
def insert_subtree($subtree; comparator):
    if . == null then
        $subtree
    else
        if ([ .data, $subtree.data ] | comparator) > 0 then
            setpath([ "left" ]; .left | insert_subtree($subtree; comparator))
        else
            setpath([ "right" ]; .right | insert_subtree($subtree; comparator))
        end
    end
;

##
# Replaces the child of node with $data with entire $subtree. Node with $data must be present in the
# tree.
# @input root node of BST. Can be null for empty tree
# @param $data data of the parent of inserted subtree
# @param $where "left" or "right", which child of parent node must be replaced with $subtree
# @param $subtree whole subtree to insert
# @param comparator comparator function
# @output modified tree
def set_child($data; $where; $subtree; comparator):
    if . == null then
        null
    else
        ([ .data, $data ] | comparator) as $comp
        | if $comp == 0 then
              # Node found
              setpath([ $where ]; $subtree)
          elif $comp > 0 and .left != null then
              # Look on the left
              setpath([ "left" ]; .left | set_child($data; $where; $subtree; comparator))
          elif .right != null then
              # Look on the right
              setpath([ "right" ]; .right | set_child($data; $where; $subtree; comparator))
          else
              error("Node with data = '\($data)' is not present in the tree")
          end
    end
;

##
# Deletes node with provided data from the tree supplied as input. Deletion uses comparator
# function.
# @input root node of BST
# @param $data data to remove from tree
# @param comparator comparator function
# @output modified tree
def delete($data; comparator):
    ([ .data, $data ] | comparator) as $comp
    |   if $comp == 0 then
            # Node found
            if is_leaf then
                null    # simply delete the leaf
            elif .left != null and .right == null then
                .left
            elif .right != null and .left == null then
                .right
            else
                # Node has two children
                (.left | last) as $succ
                | node($succ;
                    ( .left | delete($succ; comparator) );
                    .right)
            end
        elif $comp < 0 then
            # Look on the right
            setpath([ "right" ]; .right | delete($data; comparator))
        else
            # Look on the left
            setpath([ "left" ]; .left | delete($data; comparator))
        end
;

##
# Rotates BST left.
# @input root node of BST
# @output rotated left BST
# @see https://en.wikipedia.org/wiki/Tree_rotation
def rotate_left:
    node(.right.data;
        node(.data;
            node(.left.data);
            node(.right.left.data));
        node(.right.right.data))
;

##
# Rotates BST right.
# @input root node of BST
# @output rotated right BST
# @see https://en.wikipedia.org/wiki/Tree_rotation
def rotate_right:
    node(.left.data;
        node(.left.left.data);
        node(.data;
            node(.left.right.data);
            node(.right.data)))
;
