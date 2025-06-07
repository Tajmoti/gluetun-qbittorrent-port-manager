#!/bin/bash

COOKIES="/tmp/cookies.txt"
API_PATH="${HTTP_S}://${QBITTORRENT_SERVER}:${QBITTORRENT_PORT}/api/v2"

try_update_port () {
  PORT=$(cat $PORT_FORWARDED)
  rm -f $COOKIES
  curl -s -c $COOKIES --data "username=$QBITTORRENT_USER&password=$QBITTORRENT_PASS" "$API_PATH/auth/login" > /dev/null || { echo "Failed to log in to qbittorrent"; return 1; }
  curl -s -b $COOKIES --data 'json={"listen_port": "'"$PORT"'"}' "$API_PATH/app/setPreferences" > /dev/null || { echo "Failed to update qbittorrent port"; return 1; }
  rm -f $COOKIES
  echo "Successfully updated qbittorrent to port $PORT"
}

update_port() {
  until try_update_port; do
    echo "Trying again in 10 seconds"
    sleep 10
  done
}

while true; do
  if [ -f $PORT_FORWARDED ]; then
    update_port
    inotifywait -mq -e close_write $PORT_FORWARDED | while read change; do
      update_port
    done
  else
    echo "Couldn't find file $PORT_FORWARDED"
    echo "Trying again in 10 seconds"
    sleep 10
  fi
done
