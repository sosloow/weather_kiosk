#!/usr/bin/env bash
set -euo pipefail

APP_NAME=${APP_NAME:-weather_server}
DEPLOY_HOST=${DEPLOY_HOST:-${1:-}}
DEPLOY_PORT=${DEPLOY_PORT:-22}
DEPLOY_USER=${DEPLOY_USER:-$USER}
DEPLOY_PATH=${DEPLOY_PATH:-/srv/weather_server}
SERVICE_USER=${SERVICE_USER:-weather}
ENV_FILE=${ENV_FILE:-/etc/weather_server/weather_server.env}

if [[ -z "$DEPLOY_HOST" ]]; then
  echo "DEPLOY_HOST is required (env var or first argument)." >&2
  exit 1
fi

REMOTE_SOURCE="$DEPLOY_PATH/source"
REMOTE_RELEASE="$DEPLOY_PATH/current"
SSH_TARGET="${DEPLOY_USER}@${DEPLOY_HOST}"

ssh -p "$DEPLOY_PORT" "$SSH_TARGET" \
  "DEPLOY_USER='$DEPLOY_USER' SERVICE_USER='$SERVICE_USER' DEPLOY_PATH='$DEPLOY_PATH' bash -s" <<'PREP'
set -euo pipefail

REMOTE_SOURCE="$DEPLOY_PATH/source"
REMOTE_RELEASE="$DEPLOY_PATH/current"

sudo mkdir -p "$REMOTE_SOURCE" "$REMOTE_RELEASE"
sudo chown -R "$DEPLOY_USER":"$DEPLOY_USER" "$REMOTE_SOURCE"
sudo chown -R "$SERVICE_USER":"$SERVICE_USER" "$REMOTE_RELEASE"
PREP

rsync -az --delete \
  -e "ssh -p ${DEPLOY_PORT}" \
  --exclude ".git" \
  --exclude "_build" \
  --exclude "deps" \
  --exclude "node_modules" \
  --exclude "tmp" \
  ./ "${SSH_TARGET}:${REMOTE_SOURCE}/"

ssh -p "$DEPLOY_PORT" "$SSH_TARGET" \
  "APP_NAME='$APP_NAME' DEPLOY_USER='$DEPLOY_USER' SERVICE_USER='$SERVICE_USER' DEPLOY_PATH='$DEPLOY_PATH' ENV_FILE='$ENV_FILE' bash -s" <<'REMOTE'
set -euo pipefail

REMOTE_SOURCE="$DEPLOY_PATH/source"
REMOTE_RELEASE="$DEPLOY_PATH/current"

sudo mkdir -p "$REMOTE_SOURCE" "$REMOTE_RELEASE"
sudo chown -R "$DEPLOY_USER":"$DEPLOY_USER" "$REMOTE_SOURCE"
sudo chown -R "$SERVICE_USER":"$SERVICE_USER" "$REMOTE_RELEASE"

cd "$REMOTE_SOURCE"
export PATH="$HOME/.local/bin:$HOME/.asdf/shims:$PATH"
export MIX_ENV=prod
asdf exec mix deps.get --only prod
asdf exec mix assets.deploy
asdf exec mix release --overwrite

sudo rsync -a --delete "_build/prod/rel/$APP_NAME/" "$REMOTE_RELEASE/"
sudo chown -R "$SERVICE_USER":"$SERVICE_USER" "$REMOTE_RELEASE"

if [[ -f "$ENV_FILE" ]]; then
  sudo -u "$SERVICE_USER" bash -c "set -a; . '$ENV_FILE'; set +a; '$REMOTE_RELEASE/bin/$APP_NAME' eval 'WeatherServer.Release.migrate'"
else
  echo "Warning: env file $ENV_FILE not found; migrations may fail." >&2
  sudo -u "$SERVICE_USER" "$REMOTE_RELEASE/bin/$APP_NAME" eval "WeatherServer.Release.migrate"
fi

sudo systemctl restart "$APP_NAME"
REMOTE
