#!/bin/sh

# Configures the host to use mail.sh as the 'mail' command with mutt.

STEP_WIDTH=54

sudoers_created=""
mail_bin_created=""

# --- Helpers ---

_step() {
    label="$1"
    len=${#label}
    count=$((STEP_WIDTH - len))
    printf "%s" "$label"
    i=0
    while [ $i -lt $count ]; do
        printf "."; i=$((i + 1))
    done
}

ok()   { printf "done\n"; }
warn() { printf "warning\n"; }
fail() { printf "failed\n"; [ -n "$1" ] && printf "%s\n" "$1"; }

# --- --revert-config ---

if [ "$1" = "--revert-config" ]; then

    _step "Checking superuser privileges"
    if [ "$(id -u)" -ne 0 ]; then
        fail "This script must be run as root or with sudo."
        exit 1
    fi
    ok

    mail_bin="/usr/local/bin/mail"

    _step "Checking if $mail_bin exists"
    if [ ! -e "$mail_bin" ]; then
        fail "$mail_bin not found"
        exit 1
    fi
    ok

    _step "Checking if $mail_bin is a script"
    if ! head -1 "$mail_bin" | grep -q "^#!"; then
        fail "$mail_bin does not look like a script (no shebang found)"
        exit 1
    fi
    ok

    _step "Checking for configuration summary"
    if ! grep -q "Configured by configHostClient.sh" "$mail_bin"; then
        fail "No configuration summary found in $mail_bin"
        exit 1
    fi
    ok

    files=$(grep "^#   - /" "$mail_bin" | sed "s/#   - //")

    for f in $files; do
        _step "Deleting $f"
        if [ ! -e "$f" ]; then
            fail "$f not found"
        elif output=$(rm "$f" 2>&1); then
            ok
        else
            fail "$output"
        fi
    done

    printf "\nChanges reverted successfully.\n"
    exit 0
fi

# --- --add-user <user> ---

if [ "$1" = "--add-user" ]; then

    target_user="$2"
    if [ -z "$target_user" ]; then
        printf "Error: --add-user requires a username.\n" >&2
        exit 1
    fi

    _step "Checking superuser privileges"
    if [ "$(id -u)" -ne 0 ]; then
        fail "This script must be run as root or with sudo."
        exit 1
    fi
    ok

    mail_bin="/usr/local/bin/mail"

    _step "Checking if $mail_bin exists"
    if [ ! -e "$mail_bin" ]; then
        fail "$mail_bin not found — run configHostClient.sh first"
        exit 1
    fi
    ok

    _step "Checking if $mail_bin is a script"
    if ! head -1 "$mail_bin" | grep -q "^#!"; then
        fail "$mail_bin does not look like a script (no shebang found)"
        exit 1
    fi
    ok

    _step "Checking if /etc/sudoers.d exists"
    if [ ! -d /etc/sudoers.d ]; then
        fail "/etc/sudoers.d: directory not found"
        exit 1
    fi
    ok

    _step "Checking if user '$target_user' exists"
    if ! id "$target_user" > /dev/null 2>&1; then
        fail "User '$target_user' not found"
        exit 1
    fi
    ok

    _step "Adding '$target_user' to mail group"
    if output=$(usermod -aG mail "$target_user" 2>&1); then
        ok
    else
        fail "$output"
        exit 1
    fi

    mutt_path=$(command -v mutt)
    sudoers_file="/etc/sudoers.d/$target_user-mutt"

    _step "Creating $sudoers_file"
    if printf "%s ALL=(mail) NOPASSWD: %s\n" "$target_user" "$mutt_path" > "$sudoers_file" 2>&1; then
        if output=$(chmod 440 "$sudoers_file" 2>&1); then
            ok
        else
            fail "$output"
            exit 1
        fi
    else
        fail
        exit 1
    fi

    printf "\nUser '%s' configured successfully.\n" "$target_user"
    exit 0
fi

# --- No flag: print usage ---

if [ -z "$1" ]; then
    printf "Please use one of these flags:\n"
    printf "  --apply-config   Applies config\n"
    printf "  --add-user       Adds a user to mail sudoers\n"
    printf "  --revert-config  Reverts config\n"
    exit 0
fi

# --- --apply-config ---

if [ "$1" != "--apply-config" ]; then
    printf "Unknown flag: %s\n" "$1" >&2
    exit 1
fi

# Step 1: superuser privileges
_step "Checking superuser privileges"
if [ "$(id -u)" -ne 0 ]; then
    fail "This script must be run as root or with sudo."
    exit 1
fi
ok

# Step 2: sudo
_step "Checking if sudo is installed"
if command -v sudo > /dev/null 2>&1; then
    ok
else
    fail "sudo not found"
    exit 1
fi

# Step 3: mutt
_step "Checking if mutt is installed"
if command -v mutt > /dev/null 2>&1; then
    ok
else
    fail "mutt not found — install it first (e.g. apt install mutt)"
    exit 1
fi

# Step 4: mail command must not exist
_step "Checking if command 'mail' already exists"
if command -v mail > /dev/null 2>&1; then
    fail "The command 'mail' already exists at $(command -v mail)"
    exit 1
fi
ok

# Step 5: /etc/sudoers.d
_step "Checking if /etc/sudoers.d exists"
if [ ! -d /etc/sudoers.d ]; then
    fail "/etc/sudoers.d: directory not found"
    exit 1
fi
ok

# Step 6: mutt already in sudoers?
_step "Checking for existing mutt entries in sudoers"
mutt_files=$(grep -rl "mutt" /etc/sudoers /etc/sudoers.d/ 2>/dev/null || true)
if [ -n "$mutt_files" ]; then
    warn
    printf "\nWarning: There is a sudoers file which has the binary mutt involved,\n"
    printf "it's very recommended to figure out by yourself which one is doing that.\n"
    printf "Do you want to continue? [s/n]: "
    read -r answer
    case "$answer" in
        s|S) printf "\n" ;;
        *) printf "Aborted.\n"; exit 1 ;;
    esac
else
    ok
fi

# Step 7: create /etc/sudoers.d/<user>-mutt
current_user="${SUDO_USER:-$(id -un)}"
mutt_path=$(command -v mutt)
sudoers_file="/etc/sudoers.d/$current_user-mutt"

_step "Creating $sudoers_file"
if printf "%s ALL=(mail) NOPASSWD: %s\n" "$current_user" "$mutt_path" > "$sudoers_file" 2>&1; then
    if output=$(chmod 440 "$sudoers_file" 2>&1); then
        sudoers_created="$sudoers_file"
        ok
    else
        fail "$output"
        exit 1
    fi
else
    fail
    exit 1
fi

# Step 8: add current user to mail group
_step "Adding '$current_user' to mail group"
if output=$(usermod -aG mail "$current_user" 2>&1); then
    ok
else
    fail "$output"
    exit 1
fi

# Step 9: chmod +x mail.sh
script_dir="$(cd "$(dirname "$0")" && pwd)"
mail_script="$script_dir/mail.sh"

_step "Adding chmod +x to mail.sh"
if output=$(chmod +x "$mail_script" 2>&1); then
    ok
else
    fail "$output"
    exit 1
fi

# Step 10: copy mail.sh to /usr/local/bin/mail
_step "Copying mail.sh to /usr/local/bin/mail"
if output=$(cp "$mail_script" /usr/local/bin/mail 2>&1); then
    mail_bin_created="/usr/local/bin/mail"
    ok
else
    fail "$output"
    exit 1
fi

# Step 11: append configuration summary
_step "Writing configuration summary to /usr/local/bin/mail"
if printf '\n# --- Configured by configHostClient.sh on %s ---\n# Files created:\n#   - %s\n#   - %s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$sudoers_created" "$mail_bin_created" >> /usr/local/bin/mail; then
    ok
else
    fail
    exit 1
fi

printf "\nAll done. Run 'mail' to browse your inbox.\n"
