# Factorio-container

[![CI](https://github.com/mrdaemon/factorio-container/actions/workflows/main-pipeline.yml/badge.svg)](https://github.com/mrdaemon/factorio-container/actions/workflows/main-pipeline.yml)

A hopefully reasonable headless factorio server container

Automatic image builds available on docker hub:
https://hub.docker.com/r/mrdaemon/factorio

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

## Will this stay up to date?
On a best effort basis, while I'm actively making use of it.
That said, the Dockerfile takes two arguments: a version number and a SHA256 checksum for the resulting file.
This makes rebuilding with a new version for your own uses trivial, should you want to.
PRs are welcome, too!

## What can I configure
There are some environment variables you can change.
The rest is going to be configuration files in the data volume, that are factorio specific.

See the Dockerfile for a list.
Also see the `docker-compose.yml` file for an example compose file.

# Quickstart

## Quick Test

1. Put your current uid in the `docker-compose.yml` file
2. `$ docker-compose up --build`
3. Data is under the `testvolume/` directory.

## Production

1. Create a user and group to use as a service account on the docker host, note the uid and gid. It can be a system user if you'd like (ex. 999:999).
2. Create a directory tree somewhere on the host to hold the game data and configurations, e.g: `mkdir -p /srv/factorio/{config,saves,mods}`
3. (optional) Place your existing configurations and saves in the relevant directories.
3. Change ownership and permissions on this directory tree to match the service account and group.
4. Run the container with `--user 999:999` where the uid and gid are the ones of the service account and group as well as the volume mount on `/opt/factorio/volume`

On first run, the container will generate a new set of configurations off the defaults and create an initial map with them. You can either place your own configs in the relevant directories, or run the container once, stop, edit the configuration files and start it back up.

The rcon password can be found under `/path/to/your/volume/rconpw`. It will be generated automatically on first run, if none is specified.
