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
noPrint="/dev/null"

userMailExist="id mail"
getMailUserId="id -u mail"
getMailGroupId="id -g mail"

if ! $userMailExist > noPrint ; then
    echo "Error: User 'mail' doesn't exist."
    echo "Please create user 'mail'."
fi
if [ ! mailUserId="$getMailUserId" ]; then
    echo "Error: Mail User Id couldn't be read."
fi
if [ ! mailGroupId="$getMailGroupId" ]; then
    echo "Error: Mail Group Id couldn't be read."
fi

export mailGroupId mailUserId

docker compose up -d
