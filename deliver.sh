#!/bin/sh
# Executed when receive mail

set -e

domain=$1
user=$2
maildir="/var/mail/$domain/$user/Maildir"

# Create Maildir structure if it doesn't exist
mkdir -p "$maildir/new" "$maildir/cur" "$maildir/tmp"
chmod 750 "$maildir" "$maildir/new" "$maildir/cur" "$maildir/tmp"

# Deliver mail with unique filename (Maildir spec)
filename="$(date +%s).$$.$( hostname)"
cat > "$maildir/new/$filename"
chmod 640 "$maildir/new/$filename"
