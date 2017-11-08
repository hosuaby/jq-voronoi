#!/usr/bin/env bash

# Wrapper to make voronoi/voronoi.jq runnable from any directory

# Get directory of this script
SCRIPT=`realpath -s $0`
BASEDIR=`dirname $SCRIPT`

jq -cM -L "$BASEDIR/voronoi" -f voronoi/voronoi.jq
