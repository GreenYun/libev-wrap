#!/bin/sh

CURL=$(command -v curl)
WGET=$(command -v wget)

URL='https://cvs.schmorp.de/libev/?view=tar'

if [ -n "$CURL" ]; then
    curl -L "${URL}" | tar xz
elif [ -n "$WGET" ]; then
    wget -O - "${URL}" | tar xz
else
    false
fi

[ $? -ne 0 ] && echo "Failed to download libev" && exit 1

exit 0
