# OpenCode on Chainguard wolfi-base.
# Base image: https://images.chainguard.dev/directory/image/wolfi-base/versions
FROM cgr.dev/chainguard/wolfi-base:latest

# Dev tooling baked into the image so it is present in every session:
# node, npm, python3, tsc (typescript), rg (ripgrep); bash and curl are
# needed by many tools and by OpenCode's own workflows; coreutils provides
# sha256sum, used to verify the OpenCode asset.
RUN apk add --no-cache bash curl git jq file patch yq build-base nodejs npm python3 py3-pip typescript ripgrep wget coreutils tmux


# OpenCode 2 (official standalone binary): the glibc variant (wolfi-base
# ships glibc as its runtime libc), placed where the default PATH finds it
# regardless of the runtime HOME override. The version, asset URL and
# sha256 are resolved at build time from OpenCode's release API — the same
# source the official installer (https://opencode.ai/v2/install) uses to
# find the newest release — so every rebuild picks up the latest binary.
# The asset is verified against the published sha256, and the binary is
# dynamically linked, so the --version check below fails the build if a
# wrong-variant asset is ever picked.
RUN set -eux; \
    case "$(uname -m)" in \
        aarch64 | arm64) arch=arm64 ;; \
        x86_64) arch=x64 ;; \
        *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
    esac; \
    asset="opencode-linux-${arch}.tar.gz"; \
    entry="$(curl -fsSL https://opencode.ai/update/api/latest/cli | \
        jq -c '.artifacts[] | select(.distribution == "opencode")')"; \
    version="$(echo "$entry" | jq -r .version)"; \
    url="$(echo "$entry" | jq -r --arg a "$asset" '.metadata.files[$a].url')"; \
    sha256="$(echo "$entry" | jq -r --arg a "$asset" '.metadata.files[$a].sha256')"; \
    echo "installing opencode ${version} from ${url}"; \
    curl -fsSL -o /tmp/opencode.tar.gz "$url"; \
    echo "${sha256}  /tmp/opencode.tar.gz" | sha256sum -c -; \
    mkdir -p /usr/local/bin; \
    tar -xzf /tmp/opencode.tar.gz -C /usr/local/bin opencode; \
    rm -f /tmp/opencode.tar.gz; \
    opencode --version

ENTRYPOINT ["opencode"]
