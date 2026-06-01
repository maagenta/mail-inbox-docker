#!/bin/sh
set -e

for f in /etc/mail/accounts /etc/mail/domains; do
    if [ ! -f "$f" ]; then
        echo "ERROR: $f not found. Mount the volume /etc/mail with the accounts and domains files."
        exit 1
    fi
done

smtpd -n -f /etc/smtpd.conf

exec smtpd -d -f /etc/smtpd.conf
