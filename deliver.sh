#!/bin/sh
# Executed when receive mail

set -e

domain=$1
user=$2

[ -z "$domain" ] || [ -z "$user" ] && echo "ERROR: missing domain or user argument" >&2 && exit 1

case "$domain$user" in
  *..* | */*) echo "ERROR: invalid characters in domain or user" >&2; exit 1 ;;
esac

echo "$domain" | grep -qE '^[a-zA-Z0-9.-]+$' || { echo "ERROR: invalid domain format" >&2; exit 1; }
echo "$user" | grep -qE '^[a-zA-Z0-9._%+-]+$' || { echo "ERROR: invalid user format" >&2; exit 1; }

[ -d "/var/mail" ] || { echo "ERROR: /var/mail is not mounted" >&2; exit 1; }

[ "$(df /var/mail | awk 'NR==2 {print $4}')" -gt 1024 ] || { echo "ERROR: insufficient disk space" >&2; exit 1; }

maildir="/var/mail/$domain/$user/Maildir"

[ -L "$maildir" ] && { echo "ERROR: maildir is a symlink" >&2; exit 1; }

# Create Maildir structure if it doesn't exist
mkdir -p "$maildir/new" "$maildir/cur" "$maildir/tmp"
chmod 750 "$maildir" "$maildir/new" "$maildir/cur" "$maildir/tmp"

# Deliver mail with unique filename (Maildir spec)
filename="$(date +%s).$$.$(hostname | tr -cd '[:alnum:].-')"
[ ! -f "$maildir/new/$filename" ] || { echo "ERROR: filename collision detected" >&2; exit 1; }
cat > "$maildir/new/$filename"
[ -s "$maildir/new/$filename" ] || { rm -f "$maildir/new/$filename"; echo "ERROR: empty message body" >&2; exit 1; }
chmod 640 "$maildir/new/$filename"
