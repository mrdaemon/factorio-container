#!/usr/bin/env bash
# Factorio Launcher
# A wrapper script so basic it might as well wear a northface jacket

PWGEN="/usr/bin/pwgen"

## Sanity Checks

# Don't run as root within the container, also indicates lack of config
if [[ $UID -eq 0 ]] ; then
    >&2 echo "ERROR: Refusing to start as root (uid 0)."
    >&2 echo "  Verify your runtime configuration."
    exit 1
fi

if [[ ! -w $FACTORIO_VOLUME ]] ; then
    >&2 echo "ERROR: Directory \"$FACTORIO_VOLUME\" is not writable"
    >&2 echo "  Did you set permissions on the volume correctly?"
    >&2 echo "  Is the container configured to run as the correct user?"
    exit 1
fi

## Initial run generation

# RCON password
if [[ ! -f $FACTORIO_VOLUME/rconpw ]] ; then
    echo "Generating initial rcon password..."
    $PWGEN 15 1 > $FACTORIO_VOLUME/rconpw || exit 1
fi

# Configuration files
mkdir -p $FACTORIO_VOLUME/exampleconfig

for i in server-settings map-gen-settings map-settings ; do
    echo "Refreshing example ${i} with latest from distribution"
    cp $FACTORIO_HOME/data/${i}.example.json $FACTORIO_VOLUME/exampleconfig/

    # In case of missing config, create from defaults
    if [[ ! -f $FACTORIO_CONFIGDIR/${i}.json ]] ; then
        >&2 echo "WARNING: ${i}.json not found, creating from example"
        cp -v $FACTORIO_HOME/data/${i}.example.json \
            $FACTORIO_CONFIGDIR/${i}.json || exit 1
    fi
done

# Presence of initial save, generate new if missing
if [[ ! -f ${FACTORIO_SAVESDIR}/save.zip ]] ; then
    $FACTORIO_HOME/bin/x64/factorio \
        --create $FACTORIO_SAVESDIR/save.zip \
        --map-gen-settings $FACTORIO_CONFIGDIR/map-gen-settings.json \
        --map-settings $FACTORIO_CONFIGDIR/map-settings.json
    echo "Initial map created using $FACTORIO_CONFIGDIR/map*.json"
fi

echo "-----------------------------------------------------------------------"
echo "$($FACTORIO_HOME/bin/x64/factorio --version | grep 'Version:')"
echo -ne "\n"
echo "FACTORIO_HOME: $FACTORIO_HOME"
echo "FACTORIO_PORT: $FACTORIO_PORT"
echo "FACTORIO_RCON_PORT: $FACTORIO_RCON_PORT"
echo "FACTORIO_SAVESDIR: $FACTORIO_SAVESDIR"
echo "FACTORIO_CONFIGDIR: $FACTORIO_CONFIGDIR"
echo "FACTORIO_MODSDIR: $FACTORIO_MODSDIR"
echo -ne "\n"
echo "-----------------------------------------------------------------------"

# Hand off to server binary
exec $FACTORIO_HOME/bin/x64/factorio \
    --port $FACTORIO_PORT \
    --rcon-port $FACTORIO_RCON_PORT \
    --rcon-password "$(cat $FACTORIO_VOLUME/rconpw)" \
    --server-settings "$FACTORIO_CONFIGDIR/server-settings.json" \
    --server-whitelist "$FACTORIO_CONFIGDIR/server-whitelist.json" \
    --server-banlist "$FACTORIO_CONFIGDIR/server-banlist.json" \
    --start-server-load-latest \
    --server-id "$FACTORIO_CONFIGDIR/server-id.json" \
    $@

