# Factorio-container

A hopefully reasonable headless factorio server container

## What is this?

Yet another headless server for Factorio made by some asshole on the internet because they felt they knew better.

## But why?

Game servers are the kind of reasonably ephemeral, self-contained services that are a good target for containers.

## What was wrong the gazillion other ones

What's different with this one is that it doesn't require a baked in UID and has the entirety of its writable data on a single volume.
That's basically all I wanted so there it is.

## Can I run this?

Sure, but whether or not you should is a different question.
Don't just pull and run random container off the internet and expect a good time, if you feel like using this, review it first.

## What can I configure
`//TODO: document this maybe`
There are some environment variables you can change.
The rest is going to be configuration files in the data volume, that are factorio specific.

See the Dockerfile for a list.

# Quickstart

1. Create a user and group to use as a service account on the docker host, note the uid and gid. It can be a system user if you'd like (ex. 999:999).
2. Create a directory tree somewhere on the host to hold the game data and configurations, e.g: `mkdir -p /srv/factorio/{config,saves,mods}`
3. (optional) Place your existing configurations and saves in the relevant directories.
3. Change ownership and permissions on this directory tree to match the service account and group.
4. Run the container with `--user 999:999` where the uid and gid are the ones of the service account and group as well as the volume mount on `/opt/factorio/volume`

On first run, the container will generate a new set of configurations off the defaults and create an initial map with them. You can either place your own configs in the relevant directories, or run the container once, stop, edit the configuration files and start it back up.

The rcon password can be found under `/path/to/your/volume/rconpw`. It will be generated automatically on first run, if none is specified.