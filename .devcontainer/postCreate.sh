#!/usr/bin/env bash
# Install the GraphAcademy AGA proxy hook.
#
# Drops sitecustomize.py into the Python user-site-packages directory so that
# every Python invocation in this codespace (Jupyter kernel, terminal, scripts)
# auto-loads it on startup. The hook reads GA_AGA_PROXY_URL from env and
# monkey-patches AuraApi.base_uri() to route SDK traffic through the proxy
# instead of api.neo4j.io.
#
# Wired into postCreateCommand AFTER setup.sh (so requirements.txt has been
# installed and graphdatascience exists) and BEFORE start-jupyter.sh (so the
# kernel is launched with the patch already in place).
set -euo pipefail

SITE_USER="$(python3 -c 'import site; print(site.getusersitepackages())')"
mkdir -p "$SITE_USER"
cp .devcontainer/sitecustomize.py "$SITE_USER/sitecustomize.py"

echo "[postCreate] AGA proxy hook installed at $SITE_USER/sitecustomize.py"
echo "[postCreate] GA_AGA_PROXY_URL is ${GA_AGA_PROXY_URL:-<unset>}"
