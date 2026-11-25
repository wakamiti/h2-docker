#!/bin/sh
# Usage: scripts/build-test.sh <h2-version> [image-name]
# Builds the image and smoke-tests it (healthcheck, JDBC over TCP, web console).
set -eu
export MSYS_NO_PATHCONV=1
V=$1; IMG=${2:-h2:$V}; NAME=h2smoke-$V; PORT=$((20000 + $$ % 20000)); WEB=$((PORT + 1))
cd "$(dirname "$0")/.."
win() { if command -v cygpath >/dev/null; then cygpath -m "$1"; else echo "$1"; fi; }
docker build --load -q --build-arg H2_VERSION="$V" -t "$IMG" . >/dev/null
docker rm -f "$NAME" >/dev/null 2>&1 || true
trap 'docker rm -f "$NAME" >/dev/null 2>&1 || true' EXIT
docker run -d --name "$NAME" -p $PORT:9092 -p $WEB:8082 "$IMG" >/dev/null
for i in $(seq 30); do
  [ "$(docker inspect -f '{{.State.Health.Status}}' "$NAME")" = healthy ] && break; sleep 1
done
[ "$(docker inspect -f '{{.State.Health.Status}}' "$NAME")" = healthy ] || { echo "FAIL $V: not healthy"; exit 1; }
CODE=000
for i in $(seq 15); do
  CODE=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:$WEB" || true)
  [ "$CODE" = 200 ] && break; sleep 1
done
[ "$CODE" = 200 ] || { echo "FAIL $V: web console ($CODE)"; exit 1; }
docker exec "$NAME" h2-shell -sql "select 1" >/dev/null || { echo "FAIL $V: h2-shell"; exit 1; }
echo "select 1;" | docker exec -i "$NAME" h2-runscript >/dev/null || { echo "FAIL $V: h2-runscript"; exit 1; }
JAR=$(win "$(mktemp -d)")/h2.jar; docker cp "$NAME:/opt/h2.jar" "$JAR"
java -cp "$JAR" scripts/Smoke.java $PORT || { echo "FAIL $V: JDBC"; exit 1; }
echo "OK $V $(docker image inspect -f '{{.Size}}' "$IMG" | awk '{printf "%.0fMB", $1/1048576}')"
