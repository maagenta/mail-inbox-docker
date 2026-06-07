#!/bin/sh

# --- Configuration (override with flags below) ---
mailFolder="./mail-data"
mailCommand='sudo -u mail mutt -f $directory'
# -------------------------------------------------

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Browse and open mailboxes stored in a Maildir mail folder.

Options:
  --mailFolder <path>   Path to the mail folder  (default: ./mail-data)
  --mailCommand <cmd>   Command to open a mailbox. Use \$directory as the
                        Maildir path placeholder  (default: mutt -f \$directory)
  -h, --help            Show this help message

Examples:
  $(basename "$0")
  $(basename "$0") --mailFolder /home/user/mail
  $(basename "$0") --mailCommand 'neomutt -f \$directory'
EOF
}

# --- Argument parsing ---
while [ $# -gt 0 ]; do
    case "$1" in
        --mailFolder)
            [ -z "$2" ] && { echo "Error: --mailFolder requires a value." >&2; exit 1; }
            mailFolder="$2"
            shift 2
            ;;
        --mailCommand)
            [ -z "$2" ] && { echo "Error: --mailCommand requires a value." >&2; exit 1; }
            mailCommand="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_help >&2
            exit 1
            ;;
    esac
done

# --- Validate mail folder ---
if [ ! -d "$mailFolder" ]; then
    echo "Error: mail folder '$mailFolder' not found." >&2
    exit 1
fi

# -- Text on top --
printf "\n\033[1m---Available mail-boxes---\033[0m\n"

# --- Build mailbox list ---
tmpfile=$(mktemp)
count=0

for domain_path in "$mailFolder"/*/; do
    [ -d "$domain_path" ] || continue
    domain=$(basename "$domain_path")

    header_shown=0
    for user_path in "${domain_path}"*/; do
        [ -d "$user_path" ] || continue
        user=$(basename "$user_path")

        if [ $header_shown -eq 0 ]; then
            printf "\033[1m%s\033[0m:\n" "$domain"
            header_shown=1
        fi

        count=$((count + 1))
        printf "%d\t%s\n" "$count" "${user_path%/}/Maildir" >> "$tmpfile"
        printf "   %d. %s@%s\n" "$count" "$user" "$domain"
    done
done

if [ $count -eq 0 ]; then
    echo "No mailboxes found in '$mailFolder'." >&2
    rm -f "$tmpfile"
    exit 1
fi

# --- Prompt ---
printf "\nSelect mailbox [1-%d]: " "$count"
read -r selection

case "$selection" in
    ''|*[!0-9]*)
        echo "Error: invalid selection — enter a number." >&2
        rm -f "$tmpfile"
        exit 1
        ;;
esac

if [ "$selection" -lt 1 ] || [ "$selection" -gt "$count" ]; then
    printf "Error: invalid selection — must be between 1 and %d.\n" "$count" >&2
    rm -f "$tmpfile"
    exit 1
fi

# --- Resolve path and open ---
directory=$(awk -F'\t' -v n="$selection" 'NR==n { print $2 }' "$tmpfile")
rm -f "$tmpfile"

eval "$mailCommand"
