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

When an email arrives, OpenSMTPD checks whether the recipient domain is in the `domains` table and the address is in the `accounts` table. If both match, the message is written to:

```
/var/mail/<domain>/<user>/Maildir/
```

All addresses map to the `mail` Unix user, which owns the Maildir files on disk.

---

## DNS records

Before deploying, add these TXT records to your domain to block unauthorized senders from using it and protect its reputation:

| Type | Name     | Value                                         |
|------|----------|-----------------------------------------------|
| TXT  | `@`      | `v=spf1 -all`                                 |
| TXT  | `*`      | `v=spf1 -all`                                 |
| TXT  | `_dmarc` | `v=DMARC1; p=reject; rua=mailto:you@domain`   |
| MX   | `@`      | your server IP                                |

---

## Quick start

**1. Prepare your config directory:**

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

**2. Build and run:**

```sh
docker compose up -d
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
├── accounts.example
└── domains.example
```

| File | Purpose |
|------|---------|
| `Dockerfile` | Alpine + OpenSMTPD image definition |
| `docker-compose.yml` | Service, port, and volume configuration |
| `smtpd.conf` | OpenSMTPD configuration (baked into image) |
| `entrypoint.sh` | Validates config files and starts the daemon |
| `accounts.example` | Example virtual accounts table |
| `domains.example` | Example accepted domains list |

---

## Volumes

| Volume | Purpose |
|--------|---------|
| `/var/mail` | Persistent Maildir storage |
| `/etc/mail` | Runtime config (`accounts` and `domains` files) |
