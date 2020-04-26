#!/usr/bin/env bash

# Wrapper to make voronoi/voronoi.jq and voronoi/voronoi_sphere.jq runnable from any directory

# Get directory of this script
SCRIPT=`realpath -s $0`
BASEDIR=`dirname $SCRIPT`

JQ_SCRIPT=voronoi/voronoi.jq

if [[ "$@" =~ --sphere || "$@" =~ -s ]]
then
  JQ_SCRIPT=voronoi/voronoi_sphere.jq
fi

jq -cM -L "$BASEDIR/voronoi" -f ${JQ_SCRIPT}
