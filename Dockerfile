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

RUN apk add --no-cache opensmtpd

# adduser mail:
#  All email addresses use the same server user mail
#  Explanation of coommand: -D no password, -H no home, -s shell
RUN id mail 2>/dev/null || adduser -D -H -h /var/mail -s /sbin/nologin mail

RUN mkdir -p /var/mail /etc/mail && \
    chown mail:mail /var/mail && \
    chmod 755 /var/mail

COPY smtpd.conf   /etc/smtpd.conf
COPY entrypoint.sh /entrypoint.sh

# Copy initial accounts and domains
COPY accounts.example   /etc/mail/accounts
COPY domains.example    /etc/mail/domains

RUN chmod 640 /etc/smtpd.conf && \
    chmod +x /entrypoint.sh

# Standard SMTP Port
EXPOSE 25

# /var/mail  → received mails (Maildir)
# /etc/mail  → accounts y domains (mount in runtime)
VOLUME ["/var/mail", "/etc/mail"]

ENTRYPOINT ["/entrypoint.sh"]
