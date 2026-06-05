#!/usr/bin/env bash
# Idempotently start a long-running Jupyter server on port 8888.
#
# Wired up to multiple devcontainer lifecycle hooks (postCreateCommand,
# postStartCommand, postAttachCommand) because Codespaces doesn't reliably
# fire all of them for API-created codespaces. The port-based readiness check
# makes repeated invocations no-ops.
#
# Auth model: the Jupyter server runs with no token / no password. The
# forwarded port's GitHub-side visibility is the auth boundary. Inside the
# codespace, port 8888 is reachable as http://localhost:8888 with no auth.
set -euo pipefail

LOG=/tmp/jupyter.log

# Already running? (Port-based check — process-name matching is fragile.)
if curl -s --max-time 2 http://localhost:8888/api/status > /dev/null 2>&1; then
    echo "[jupyter] already running on port 8888"
    exit 0
fi

# Install Jupyter if it's somehow missing (requirements.txt usually covers this).
if ! command -v jupyter > /dev/null 2>&1; then
    echo "[jupyter] jupyter binary not found, installing..."
    pip install --quiet jupyter jupyter-server
fi

echo "[jupyter] $(date) starting jupyter server" >> "$LOG"
SHELL=/bin/bash nohup jupyter server \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --ServerApp.token='' \
    --ServerApp.password='' \
    --ServerApp.disable_check_xsrf=True \
    --ServerApp.allow_origin='*' \
    --ServerApp.allow_remote_access=True \
    --ServerApp.root_dir="${PWD}" \
    >> "$LOG" 2>&1 &

# Readiness probe — 30s upper bound. Fresh Codespaces routinely take 10-20
# seconds for jupyter-server to finish importing extensions and bind to the
# socket. The previous 8s window tripped postCreateCommand reliably with no
# functional impact (jupyter is nohup-backgrounded and keeps starting), but
# left a misleading "exit code 1" in the creation log.
for i in $(seq 1 30); do
    if curl -s --max-time 2 http://localhost:8888/api/status > /dev/null 2>&1; then
        echo "[jupyter] started on port 8888 (logs: $LOG)"
        exit 0
    fi
    sleep 1
done

echo "[jupyter] failed to come up in 30 seconds; check $LOG"
tail -n 30 "$LOG" 2>/dev/null
exit 1
