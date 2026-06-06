#!/bin/sh
#  ___            ___
# /   \          /   \
# \_   \        /  __/
#  _\   \      /  /__
#  \___  \____/   __/
#      \_       _/
#        | @  @   \_
#        |                M A A G E N T A
#      _/     /\
#     /o)  (o/\ \_
#     \_____/ /
#       \____/
if ! id mail > /dev/null 2>&1 ; then
    echo "Error: User 'mail' doesn't exist."
    echo "Please create user 'mail'."
    exit 1
fi

HOST_MAIL_UID=$(id -u mail)
HOST_MAIL_GID=$(id -g mail)

if [ -z "$HOST_MAIL_UID" ]; then
    echo "Error: Mail User Id couldn't be read."
    exit 1
fi
if [ -z "$HOST_MAIL_GID" ]; then
    echo "Error: Mail Group Id couldn't be read."
    exit 1
fi

export HOST_MAIL_UID HOST_MAIL_GID

docker compose up -d
