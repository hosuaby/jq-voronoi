#!/usr/bin/env bash

# Get directory of this script
SCRIPT=`realpath -s $0`
BASEDIR=`dirname $SCRIPT`

jq -cM -L "$BASEDIR/voronoi" -f voronoi/voronoi-sphere.jq