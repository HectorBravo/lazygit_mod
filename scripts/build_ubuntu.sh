#!/usr/bin/env bash
#
# Builds the Ubuntu (linux/amd64) binary with Docker, so no local Go
# toolchain is required. The result is a statically linked binary
# (CGO_ENABLED=0) written to the repository root as ./lazygit, owned by the
# invoking user. Usage:
#
#   scripts/build_ubuntu.sh
#
# Override the output name with the OUT environment variable, e.g.
# OUT=build/lazygit-ubuntu scripts/build_ubuntu.sh
#
# -buildvcs=false skips Go's VCS stamping step, which runs git in the
# mounted source tree and fails inside the container.

set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(dirname "$script_dir")
out=${OUT:-$repo_root/lazygit}

# The Go build cache, persisted across runs in the user's cache directory.
# It must live outside the mounted repo so the build doesn't pollute the
# working tree, and it is mounted writable because the container's default
# location is not writable by a non-root user.
cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/lazygit-docker-build
mkdir -p "$cache_dir"

cd "$repo_root"

docker run --rm \
    --user "$(id -u):$(id -g)" \
    -v "$repo_root":/src:ro \
    -v "$repo_root":/out \
    -v "$cache_dir":/gocache \
    -w /src \
    golang:1.25 \
    sh -c "CGO_ENABLED=0 GOCACHE=/gocache GOFLAGS=-buildvcs=false go build -o /out/$(basename "$out") ."

echo "Built $out"
