#!/bin/sh
set -e

# Copy accounts/domains file in case there are no files in the host bind mount
cp -n /etc/mail-default/accounts /etc/mail/accounts;
cp -n /etc/mail-default/domains /etc/mail/domains;
     
for f in /etc/mail/accounts /etc/mail/domains; do
    if [ ! -f "$f" ]; then
        echo "ERROR: $f not found. Mount the volume /etc/mail with the accounts and domains files."
        exit 1
    fi
done

smtpd -n -f /etc/smtpd.conf

exec smtpd -d -f /etc/smtpd.conf
