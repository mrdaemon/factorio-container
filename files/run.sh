#!/usr/bin/env bash
# Factorio Launcher
# This wrapper script handles preparing configuration files,
# generating missing ones (if any) and then starting up the server

# Path to necessary binaries
PWGEN="/usr/bin/pwgen"

## Sanity Checks

# Don't run as root within the container, also indicates lack of config
if [[ $UID -eq 0 ]] ; then
    >&2 echo "ERROR: Refusing to start as root (uid 0)."
    >&2 echo "  Verify your container configuration."
    >&2 echo "  Make sure a user and group are specified at runtime."
    exit 1
fi

# Verify that the user we're running as can write to the container
if [[ ! -w $FACTORIO_VOLUME ]] ; then
    >&2 echo "ERROR: Volume at '$FACTORIO_VOLUME' is not writable"
    >&2 echo "  Did you set permissions on the host directory correctly?"
    >&2 echo "  Is the container configured to run as the correct user?"
    exit 1
fi

# Ensure base directories are present in volume
for d in "$FACTORIO_CONFIGDIR" "$FACTORIO_SAVESDIR" "$FACTORIO_MODSDIR" ; do
    if [[ ! -d $d ]] ; then
        >&2 echo "WARNING: $d is missing in volume, creating..."
        mkdir -p "$d" || exit 1
    fi
done

## Initial run generation

# RCON password
if [[ ! -f $FACTORIO_VOLUME/rconpw ]] ; then
    echo "Generating initial rcon password..."
    $PWGEN 15 1 > "$FACTORIO_VOLUME/rconpw" || exit 1
fi

# Configuration files
mkdir -p "$FACTORIO_VOLUME/exampleconfig"

for i in server-settings map-gen-settings map-settings ; do
    echo "Refreshing example ${i} with latest from distribution"
    cp "$FACTORIO_HOME/data/${i}.example.json" "$FACTORIO_VOLUME/exampleconfig/"

    # In case of missing config, create from defaults
    if [[ ! -f $FACTORIO_CONFIGDIR/${i}.json ]] ; then
        >&2 echo "WARNING: ${i}.json not found, creating from example"
        cp -v "$FACTORIO_HOME/data/${i}.example.json" \
            "$FACTORIO_CONFIGDIR/${i}.json" || exit 1
    fi
done

# Presence of initial save, generate new if missing
if [[ ! -f ${FACTORIO_SAVESDIR}/save.zip ]] ; then
    >&2 echo "WARNING: Initial save file not found, generating new map..."
    "$FACTORIO_HOME"/bin/x64/factorio \
        --create "$FACTORIO_SAVESDIR"/save.zip \
        --map-gen-settings "$FACTORIO_CONFIGDIR"/map-gen-settings.json \
        --map-settings "$FACTORIO_CONFIGDIR"/map-settings.json || exit 1
    echo "Initial map created using settings from $FACTORIO_CONFIGDIR/"
    echo "If you wish to change this, edit the settings, delete save.zip"
    echo "and start the container again."
fi

echo "-----------------------------------------------------------------------"
"$FACTORIO_HOME"/bin/x64/factorio --version | grep 'Version:'
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
exec "$FACTORIO_HOME"/bin/x64/factorio \
    --port "$FACTORIO_PORT" \
    --rcon-port "$FACTORIO_RCON_PORT" \
    --rcon-password "$(head -n 1 "$FACTORIO_VOLUME/rconpw")" \
    --server-settings "$FACTORIO_CONFIGDIR/server-settings.json" \
    --use-server-whitelist \
    --server-whitelist "$FACTORIO_CONFIGDIR/server-whitelist.json" \
    --server-banlist "$FACTORIO_CONFIGDIR/server-banlist.json" \
    --start-server-load-latest \
    --server-id "$FACTORIO_CONFIGDIR/server-id.json" \
    "$@"

