# Isolated OpenCode (Podman) for Mac

Run OpenCode in a Linux container on Mac. The agent gets its own auth, skills,
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

Plugin and skill updates: before every launch, `./oc` runs two updates in a
one-shot container:

- `opencode plugin update` — all configured package plugins (npm or git) and
  the skills those plugins bundle. Pinned exact versions/commits are skipped
  (OpenCode's own behavior).
- `npx skills update -p -g` — all skills managed by the skills CLI, in both
  project and global scope.

Not updated: local plugins (plain files in the isolated config), skills not
installed by the skills CLI, and the OpenCode binary itself — that is
`./oc --build` / auto-update.

Also available:
```
./oc --update             # just update plugins and skills, then exit
./oc --update --build     # rebuild the image first, then update
```

If an update fails (e.g. no network), `./oc` on a normal launch warns and
starts the TUI anyway. `./oc --update` exits with an error instead.

## Isolation

Mounted: the project at `/workspace` (read-write).

Not inherited: host OpenCode config, host env, host API keys, project
`opencode.json` / `.opencode/`.

This is a fence around the agent, not a sandbox for a malicious repo.
