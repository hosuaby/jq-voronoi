#!/usr/bin/env bash

# Get directory of this script
SCRIPT=`realpath -s $0`
BASEDIR=`dirname $SCRIPT`

# Build sketch as application if it was not built yet
if [ ! -d "$BASEDIR/display/built" ]; then
    cd $BASEDIR
    processing-java --sketch=display --output=./display/built --export
fi

"$BASEDIR"/display/built/display "$@"
