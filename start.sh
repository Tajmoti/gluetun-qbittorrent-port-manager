#!/bin/bash

COOKIES="/tmp/cookies.txt"
API_PATH="${HTTP_S}://${QBITTORRENT_SERVER}:${QBITTORRENT_PORT}/api/v2"

try_update_port () {
  port=$(cat "$PORT_FORWARDED")
  [ "$port" ] || { echo "Unable to read a port from $PORT_FORWARDED"; return 1; }
  rm -f $COOKIES
  curl -s -c $COOKIES --data "username=$QBITTORRENT_USER&password=$QBITTORRENT_PASS" "$API_PATH/auth/login" > /dev/null || { echo "Failed to log in to qbittorrent"; return 2; }
  curl -s -b $COOKIES --data 'json={"listen_port": "'"$port"'"}' "$API_PATH/app/setPreferences" > /dev/null || { echo "Failed to update qbittorrent port"; return 2; }
  rm -f $COOKIES
  echo "Successfully updated qbittorrent to port $port"
}

dir="$(dirname "$PORT_FORWARDED")"
nam="$(basename "$PORT_FORWARDED")"

while read -r _; do
  while true; do
    try_update_port
    [ $? -ne 2 ] && break
    echo "Trying again in 10 seconds"
    sleep 10
  done
done < <(echo "init"; inotifywait -mq --format '%e' -e close_write -e delete "$dir" --include "$nam")
