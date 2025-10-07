#!/usr/bin/env bash
set -e

echo "Starting Postfix container..."

# Create directory for mail storage
mkdir -p /data/mail_in
chown nobody:nogroup /data/mail_in
chmod 777 /data/mail_in

# Basic Postfix configuration
postconf -e "inet_interfaces = all"
postconf -e "mydestination = localhost, server.local"
postconf -e "mynetworks = 127.0.0.0/8, 172.16.0.0/12, 10.0.0.0/8, 192.168.0.0/16"
postconf -e "alias_maps = hash:/etc/aliases"
postconf -e "alias_database = hash:/etc/aliases"
postconf -e "local_recipient_maps ="

# Allow any local recipient (so display@server.local works)
postconf -e "local_recipient_maps ="

# MESSAGE SIZE LIMITS:
postconf -e "message_size_limit = 524288000"    # 500MB limit
postconf -e "mailbox_size_limit = 1073741824"   # 1GB mailbox limit
postconf -e "virtual_mailbox_limit = 1073741824" # 1GB virtual mailbox limit

# Create a simple save script
cat > /usr/local/bin/save-mail.sh <<'SH'
#!/bin/bash
TS=$(date +%s%N)
OUT="/data/mail_in/incoming-${TS}.eml"
echo "SAVE-MAIL: Starting delivery to $OUT" >&2
cat > "$OUT"
echo "SAVE-MAIL: Saved to $OUT ($(wc -c < "$OUT") bytes)" >&2
chmod 666 "$OUT"
SH

chmod +x /usr/local/bin/save-mail.sh

# Set up aliases - ONLY LOCAL NAMES, no @ symbols!
echo "display: |/usr/local/bin/save-mail.sh" > /etc/aliases
echo "test: |/usr/local/bin/save-mail.sh" >> /etc/aliases
newaliases

echo "Postfix configuration complete"
echo "Starting Postfix in foreground..."

# Start Postfix
exec /usr/sbin/postfix start-fg
