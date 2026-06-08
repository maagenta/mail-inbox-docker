# inbox-server-docker

_Minimal Docker image for receiving email using [OpenSMTPD](https://www.opensmtpd.org/) on Alpine Linux._

This container (by default called `mail-inbox`) is intended to create a small multi-domain and multi-user mailbox which stores the mail in Maildir format in a personalized host bind folder. It doesn't have IMAP, POP, or outbound capabilities. Mail is stored in Maildir format and read directly from the filesystem.

This repository also includes scripts to configure how to read the email directly from the host using the `mutt` client.

## How the Container Works
The container listens on port `25` using OpenSMTPD internally. When an email arrives, if the domain and the account are in the tables (it will be explained later) the message is handed off to `deliver.sh` which saves it and manages the permissions.

### Accounts and Domain Tables
The container uses the `accounts` and `domains` tables, both files have to be stored in one host folder which by default is `./mail-config` which is bound to `/etc/mail` in the container. 

```
mail-config/
└── accounts
└── domains
```

* The `domains` table stores the mail domains ex: `domain.com`
* The `accounts` table stores the accounts and maps them to the `mail` user ex: `user@domain.com  mail`

#### Adding a domain
Just add a line with the domain in the domains file.

```
echo 'example.com' > <mail-config>/domains
```

#### Adding an account
Add a line with the account followed by `mail`.

```
echo 'user@example.com   mail' > <mail-config>/accounts
```

#### Updating container tables
To update the container tables, restart it.

```
docker restart <mail-inbox-docker-container>
```

 #### Mail storage
 The mail is stored using the _Maildir_ standard in the container in the `/var/mail` volume which is by default bound to `./mail-data`. It follows the structure below.
 
 ```
<mail-folder>/<domain>/<account>/Maildir/new/
```

It can be seen clearly with an example.

```
<mail-folder>/
└── domain.com/
    └── admin/
        └── Maildir/
            ├── new/    ← unread messages
            ├── cur/    ← read messages
            └── tmp/
```

##### Owners
All folders and files are owned by `mail` in both the container and the host. When the container is composed using `setup.sh` it automatically reads the UID/GID of `mail` on the host and copies them into the container.

##### Permissions
To avoid deleting data by accident and strengthen security, `deliver.sh` assigns a strong permissions policy to the `<mail-folder>`.
* Folders have `750`
* Files (Messages) use `640`

### Volumes
The container uses two volumes, separating runtime config and mail storage.

| Volume | Default Host Path | Purpose |
|--------|-----------|---------|
| /var/mail | ./mail-data | Persistent Maildir storage |
| /etc/mail | ./mail-config | Runtime config |

## Setup Docker Container

All the steps to have a successful docker container have been written in the script `setup.sh`. So just run it and it will set up the container.

```sh
./setup.sh
```

### What does setup.sh do?
1. Read the UID/GID of the host `mail` user
2. Check UID/GID and permissions of the `mail-data` folder if there are files there  
3. Export them as `HOST_MAIL_UID` and `HOST_MAIL_GID`
4. Run `docker compose up -d`
The image is built with those values so the container's `mail` user matches the host.

---

## (Optional) Configure Host Client
On top of the container, the repo has the script `configHostClient.sh` which configures the host machine so that the `mail` command runs `mail.sh` (a mutt-based wrapper) system-wide.

### Dependencies
The package `mutt` must be installed

### What does configHostClient.sh do?
When the script is run without using flags, it will show help. The flag to apply the configuration is `--apply-config`

```sh
sudo ./configHostClient.sh --apply-config
```

With that flag, the script:
1. Install `mail.sh` as `/usr/local/bin/mail`
2. Create the sudoers rule making the current user able to run `mutt` as `mail` from the current session.
3. Add the current user to the `mail` group.
4. Prevent `mutt` from asking to create user folders.

### Additional flags

```
--add-user <username> --------> Grant access to additional users
--del-user <username> --------> Remove user's access
--revert-config <username> ---> Revert all changes made by the script
```

---

## File structure


| File | Purpose |
|------|---------|
| _Dockerfile_ | Image definition |
| _docker-compose.yml_ | Service, port, and volume configuration |
| _smtpd.conf_ | OpenSMTPD configuration (baked into image) |
| _entrypoint.sh_ | Copies default config if absent, validates smtpd.conf, starts the daemon |
| _deliver.sh_ | Creates Maildir structure and writes incoming messages |
| _setup.sh_ | Setup the container |
| _mail.sh_ | Interactive mailbox browser |
| _configHostClient.sh_ | Configures the host mail client |
| _accounts.example_ | Example virtual accounts table |
| _domains.example_ | Example accepted domains list |
