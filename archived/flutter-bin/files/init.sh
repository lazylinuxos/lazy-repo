#!/bin/sh

export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

APP_DIR=/opt/flutter
SAVE_DIR="$XDG_CACHE_HOME/flutter-rw"
WORK_DIR="$XDG_CACHE_HOME/flutter-work"
MOUNT_DIR="$XDG_CACHE_HOME/flutter-sdk"

if [ "$(id -u)" = 0 ]; then
    export FLUTTER_ROOT="$APP_DIR"
    return
fi

if [ ! -e "$MOUNT_DIR/bin/flutter" ]; then
	mkdir -p "$SAVE_DIR" "$WORK_DIR" "$MOUNT_DIR"

    fuse-overlayfs \
        -o lowerdir="$APP_DIR" \
        -o upperdir="$SAVE_DIR" \
        -o workdir="$WORK_DIR" \
        "$MOUNT_DIR"
fi

export FLUTTER_ROOT="$MOUNT_DIR"
export PATH="$FLUTTER_ROOT/bin:$PATH"
