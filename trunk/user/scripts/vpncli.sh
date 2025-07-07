#!/bin/sh

# Default domain to query (can be overridden by subscription URL domain)
MAIN="test.asevc.online"
CONFIG_FILE="/etc/storage/openvpn/client.conf"
BACKUP_KEY="/etc/storage/openvpn/backup-client.conf"
LOG_FILE="/tmp/vpncli.log"
TEMP_DIR="/tmp/openvpn_keys"
DNS_LOOKUP_SERVICE="http://155.138.137.176:8000/nslookup/"

# Logging function
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# Create temp directory if it doesn't exist
if [ ! -d "$TEMP_DIR" ]; then
    mkdir -p "$TEMP_DIR"
fi

# Create openvpn directory if it doesn't exist
if [ ! -d "/etc/storage/openvpn" ]; then
    mkdir -p /etc/storage/openvpn
fi

# Get subscription URL from nvram
SUBSCRIPTION_URL=$(nvram get vpnc_peer)

if [ -z "$SUBSCRIPTION_URL" ]; then
    log_message "Error: No subscription URL provided."
    exit 1
fi

# Check if VPN client is enabled
VPNC_ENABLE=$(nvram get vpnc_enable)
if [ "$VPNC_ENABLE" != "1" ]; then
    log_message "VPN client is disabled. Not connecting."
    nvram set vpnc_state_t=0
    killall openvpn >/dev/null 2>&1
    exit 0
fi

# Extract key name from subscription URL
KEY_NAME=$(echo "$SUBSCRIPTION_URL" | awk -F'/' '{print $NF}')
if [ -z "$KEY_NAME" ]; then
    log_message "Error: Could not parse key name from URL: $SUBSCRIPTION_URL"
    KEY_NAME="default_key"
fi

# Extract domain from subscription URL if available
if echo "$SUBSCRIPTION_URL" | grep -q "http"; then
    DOMAIN=$(echo "$SUBSCRIPTION_URL" | sed -n 's|^https\?://\([^/]*\).*|\1|p')
    if [ ! -z "$DOMAIN" ]; then
        MAIN="$DOMAIN"
    fi
fi

log_message "Using domain: $MAIN and key: $KEY_NAME"

# 1. Get IP from DNS TXT record using nslookup
log_message "Requesting DNS TXT record for $MAIN via nslookup API"
DNS_RESPONSE=$(wget -q -O - "${DNS_LOOKUP_SERVICE}?domain=$MAIN")

if [ -z "$DNS_RESPONSE" ]; then
    log_message "Error: Could not get DNS TXT record for $MAIN."
    exit 1
fi

# Extract IP address from TXT record
IP=$(echo "$DNS_RESPONSE" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
if [ -z "$IP" ]; then
    log_message "Error: Could not extract IP address from DNS TXT record."
    exit 1
fi
log_message "IP address obtained: $IP"

# 2. Check server availability
API_URL="http://${IP}/api/keys/download/${KEY_NAME}"
log_message "Checking server availability: $API_URL"
wget -q -O - "$API_URL" | grep "proto" > /dev/null

if [ $? -eq 0 ]; then
    log_message "Server available. Downloading new key."
    
    # 3. Download new key
    TEMP_KEY_FILE="$TEMP_DIR/${KEY_NAME}_key.conf"
    wget -q -O "$TEMP_KEY_FILE" "$API_URL"
    
    if [ $? -eq 0 ] && [ -s "$TEMP_KEY_FILE" ]; then
        log_message "Key successfully downloaded. Replacing key in $CONFIG_FILE"
        mv "$TEMP_KEY_FILE" "$CONFIG_FILE"
        # Also save as backup
        cp "$CONFIG_FILE" "$BACKUP_KEY"
    else
        log_message "Error downloading key. Using last available key."
        rm -f "$TEMP_KEY_FILE"
        # Try to use backup if it exists
        if [ -f "$BACKUP_KEY" ]; then
            cp "$BACKUP_KEY" "$CONFIG_FILE"
        else
            log_message "No backup key available."
            nvram set vpnc_state_t=0
            exit 1
        fi
    fi
else
    log_message "Server unavailable. Using last available key."
    if [ -f "$BACKUP_KEY" ]; then
        cp "$BACKUP_KEY" "$CONFIG_FILE"
    else
        log_message "No backup key available."
        nvram set vpnc_state_t=0
        exit 1
    fi
fi

# 4. Start OpenVPN
log_message "Starting OpenVPN with configuration $CONFIG_FILE"
killall openvpn >/dev/null 2>&1
/usr/sbin/openvpn --config "$CONFIG_FILE" --daemon

if [ $? -eq 0 ]; then
    log_message "OpenVPN successfully started."
    nvram set vpnc_state_t=1
else
    log_message "Error starting OpenVPN."
    nvram set vpnc_state_t=0
    exit 1
fi

exit 0