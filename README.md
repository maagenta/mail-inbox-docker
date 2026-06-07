```
 ___            ___
/   \          /   \
\_   \        /  __/
 _\   \      /  /__
 \___  \____/   __/
     \_       _/
       | @  @   \_
       |                M A A G E N T A
     _/     /\
    /o)  (o/\ \_
    \_____/ /
      \____/
```

# inbox-server-docker

Minimal Docker image for receiving email using [OpenSMTPD](https://www.opensmtpd.org/) on Alpine Linux.

Receive-only — no IMAP, no POP, no outbound relay. Mail is stored in Maildir format and read directly from the filesystem.

---

## How it works

When an email arrives, OpenSMTPD checks whether the recipient domain is in the `domains` table and the address is in the `accounts` table. If both match, the message is handed off to `deliver.sh`, which creates the Maildir structure and writes the message to:

```
/var/mail/<domain>/<user>/Maildir/new/
```

All addresses map to the `mail` Unix user, which owns the Maildir files on disk. The container's `mail` user is created with the same UID/GID as the host's `mail` user, so bind-mounted files are accessible from the host without permission issues.

---

## DNS records

Before deploying, add these records to your domain to block unauthorized senders and protect its reputation:

| Type | Name     | Value                                       |
|------|----------|---------------------------------------------|
| MX   | `@`      | your server IP                              |
| TXT  | `@`      | `v=spf1 -all`                               |
| TXT  | `*`      | `v=spf1 -all`                               |
| TXT  | `_dmarc` | `v=DMARC1; p=reject; rua=mailto:you@domain` |

---

## Quick start

**1. Create the host `mail` user** (if it doesn't exist):

```sh
sudo useradd -r -s /sbin/nologin mail
```

**2. Prepare your config directory:**

```sh
mkdir mail-config

# accounts — one address per line, mapped to the mail Unix user
cat > mail-config/accounts <<EOF
admin@yourdomain.com   mail
info@yourdomain.com    mail
EOF

# domains — one domain per line
cat > mail-config/domains <<EOF
yourdomain.com
EOF
```

**3. Build and run:**

```sh
./setup.sh
```

`setup.sh` reads the UID/GID of the host `mail` user, exports them as `HOST_MAIL_UID` and `HOST_MAIL_GID`, and runs `docker compose up -d`. The image is built with those values so the container's `mail` user matches the host.

> **Without a `mail-config/` mount**, the container falls back to the example accounts and domains baked into the image.

**4. Configure the host client:**

```sh
sudo ./configHostClient.sh --apply-config
```

Installs `mail.sh` as `/usr/local/bin/mail`, creates the sudoers rule, and adds the current user to the `mail` group.

**5. Grant access to additional users** (optional):

```sh
sudo ./configHostClient.sh --add-user <username>
```

**To undo the configuration:**

```sh
sudo ./configHostClient.sh --revert-config
```

---

## Reading mail

Received messages are stored in `./mail-data/` on the host:

```
mail-data/
└── yourdomain.com/
    └── admin/
        └── Maildir/
            ├── new/    ← unread messages
            ├── cur/    ← read messages
            └── tmp/
```

Each file in `new/` is a plain text email. Read it with:

```sh
cat mail-data/yourdomain.com/admin/Maildir/new/<filename>
```

---

## File structure

```
inbox-server-docker/
├── Dockerfile
├── docker-compose.yml
├── smtpd.conf
├── entrypoint.sh
├── deliver.sh
├── setup.sh
├── mail.sh
├── configHostClient.sh
├── accounts.example
└── domains.example
```

| File | Purpose |
|------|---------|
| `Dockerfile` | Alpine + OpenSMTPD image definition |
| `docker-compose.yml` | Service, port, and volume configuration |
| `smtpd.conf` | OpenSMTPD configuration (baked into image) |
| `entrypoint.sh` | Copies default config if absent, validates smtpd.conf, starts the daemon |
| `deliver.sh` | MDA script — creates Maildir structure and writes incoming messages |
| `setup.sh` | Reads host `mail` UID/GID and runs `docker compose up -d` |
| `mail.sh` | Interactive mailbox browser — lists and opens Maildir mailboxes with mutt |
| `configHostClient.sh` | Configures the host client (`--add-user`, `--revert-config`) |
| `accounts.example` | Example virtual accounts table |
| `domains.example` | Example accepted domains list |

---

## Volumes

| Volume | Host path | Purpose |
|--------|-----------|---------|
| `/var/mail` | `./mail-data` | Persistent Maildir storage |
| `/etc/mail` | `./mail-config` | Runtime config (`accounts` and `domains` files) |
