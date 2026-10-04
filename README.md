# Isolated OpenCode (Podman) for Mac

Run OpenCode in a Linux container. The agent gets its own auth, skills,
and config. Your Mac's `~/.config/opencode` is never mounted.

## Once

```
brew install podman
podman machine init
```

Do consider configuring your podman machine with adequate memory and CPU allocation; https://docs.podman.io/en/stable/markdown/podman-machine-set.1.html
`./oc` starts the machine if it is stopped, and stops it when you quit.

## Run

```
./oc                          # current directory
./oc /path/to/project
./oc /path/to/project --help
```

First time: the TUI has no providers. Run `/connect` inside it. Keys
stay in the `opencode-isolated` volume.

## Reset / update

```
podman volume rm opencode-isolated    # wipe isolated auth + skills
```

`./ocOld` pulls `ghcr.io/anomalyco/opencode:latest` on every launch, so a
newer OpenCode release is picked up automatically on the next run. This is a clean approach; no tools like node, npm, typescript etc. are in this image, so it will have to be installed every time you need it. Personal preference what you need.

## oc (wolfi-base image, tools baked in)

`./oc` runs OpenCode from a local image `opencode-wolfi` built on
Chainguard `wolfi-base` with node, npm, python3, typescript, and ripgrep
baked etc. in, so dev tools are present in every session without installing
them first (see Containerfile and tailor to your needs). OpenCode is installed into the image from its official
release. State (auth, skills, plugins, config) lives in the same
`opencode-isolated` volume as `./oc`, so either launcher is a drop-in
fallback for the other.

First launch builds the image from `Containerfile` automatically:

```
./oc                     # current directory
./oc /path/to/project
```

Refresh the base image and the OpenCode binary:

```
./oc --build /path/to/project
```

Reset is the same: `podman volume rm opencode-isolated`.

## Isolation

Mounted: the project at `/workspace` (read-write).

Not inherited: host OpenCode config, host env, host API keys, project
`opencode.json` / `.opencode/`.

This is a fence around the agent, not a sandbox for a malicious repo.
