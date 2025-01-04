#!/bin/sh

CURL=$(command -v curl)
WGET=$(command -v wget)

if [ -n "$CURL" ]; then
    curl -L 'https://cvs.schmorp.de/libev/?view=tar' | tar xz
elif [ -n "$WGET" ]; then
    wget -O - 'https://cvs.schmorp.de/libev/?view=tar' | tar xz
else
    false
fi

[ $? -ne 0 ] && echo "Failed to download libev" && exit 1
