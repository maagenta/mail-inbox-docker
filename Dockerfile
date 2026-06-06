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

## Docker image to receive eMails

FROM alpine:3.20

# Recreate mail user/group with host UID/GID so bind mount files are accessible from host
# -D no password, -H no home, -s shell
ARG HOST_MAIL_UID=1000
ARG HOST_MAIL_GID=1000

RUN deluser mail && \
    delgroup mail && \
    addgroup -g ${HOST_MAIL_GID} mail && \
    adduser -D -H -u ${HOST_MAIL_UID} -G mail -s /sbin/nologin mail && \
    apk add --no-cache opensmtpd

RUN mkdir -p /var/mail /etc/mail && \
    chown mail:mail /var/mail /etc/mail && \
    chmod 750 /var/mail /etc/mail

COPY smtpd.conf   /etc/smtpd.conf
COPY entrypoint.sh /entrypoint.sh
COPY deliver.sh   /usr/local/bin/deliver.sh

# Copy initial accounts and domains
COPY accounts.example   /etc/mail-default/accounts
COPY domains.example    /etc/mail-default/domains

RUN chmod 640 /etc/smtpd.conf && \
    chmod +x /entrypoint.sh /usr/local/bin/deliver.sh

# Standard SMTP Port
EXPOSE 25

# /var/mail  → received mails (Maildir)
# /etc/mail  → accounts y domains (mount in runtime)
VOLUME ["/var/mail", "/etc/mail"]

ENTRYPOINT ["/entrypoint.sh"]
