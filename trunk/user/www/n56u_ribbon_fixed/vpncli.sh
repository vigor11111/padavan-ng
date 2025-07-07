#!/bin/bash

# Default domain to query (can be overridden by subscription URL domain)
MAIN="test.asevc.online"
CONFIG_FILE="/etc/openvpn/client/client.conf"
BACKUP_KEY="/etc/openvpn/client/backup-client.conf"
LOG_FILE="/var/log/openvpn_subscription_update.log"
TEMP_DIR="/tmp/openvpn_keys"
DNS_LOOKUP_SERVICE="http://155.138.137.176:8000/nslookup/"

# Logging function
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

# Create temp directory if it doesn't exist
if [[ ! -d "$TEMP_DIR" ]]; then
    mkdir -p "$TEMP_DIR"
fi

# Get subscription URL from nvram
SUBSCRIPTION_URL=$(nvram get vpnc_peer)

if [[ -z "$SUBSCRIPTION_URL" ]]; then
    log_message "Error: No subscription URL provided."
    exit 1
fi

# Check if VPN client is enabled
VPNC_ENABLE=$(nvram get vpnc_enable)
if [[ "$VPNC_ENABLE" != "1" ]]; then
    log_message "VPN client is disabled. Not connecting."
    nvram set vpnc_state_t=0
    exit 0
fi

# Extract key name and domain from subscription URL
if [[ $SUBSCRIPTION_URL =~ https?://([^/]+)/api/keys/download/([^/]+) ]]; then
    DOMAIN="${BASH_REMATCH[1]}"
    KEY_NAME="${BASH_REMATCH[2]}"
    # If domain is found in the URL, use it instead of default
    if [[ ! -z "$DOMAIN" ]]; then
        MAIN="$DOMAIN"
    fi
else
    # Try to extract just the key name if URL format is different
    KEY_NAME=$(echo "$SUBSCRIPTION_URL" | awk -F'/' '{print $NF}')
    if [[ -z "$KEY_NAME" ]]; then
        log_message "Error: Could not parse key name from URL: $SUBSCRIPTION_URL"
        KEY_NAME="default_key"
    fi
    log_message "Using domain: $MAIN and key: $KEY_NAME"
fi

# 1. Get IP from DNS TXT record using nslookup
log_message "Requesting DNS TXT record for $MAIN via nslookup API"
DNS_RESPONSE=$(curl -s "${DNS_LOOKUP_SERVICE}?domain=$MAIN")

if [[ -z "$DNS_RESPONSE" ]]; then
    log_message "Error: Could not get DNS TXT record for $MAIN."
fi

# Extract IP address from TXT record
IP=$(echo "$DNS_RESPONSE" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
if [[ -z "$IP" ]]; then
    log_message "Error: Could not extract IP address from DNS TXT record."
fi
log_message "IP address obtained: $IP"

# 2. Check server availability
API_URL="http://${IP}/api/keys/download/${KEY_NAME}"
log_message "Checking server availability: $API_URL"
curl --connect-timeout 5 "$API_URL" | grep "proto" > /dev/null

if [[ $? -eq 0 ]]; then
    log_message "Server available. Downloading new key."
    
    # 3. Download new key
    TEMP_KEY_FILE="$TEMP_DIR/${KEY_NAME}_key.conf"
    curl -s "$API_URL" -o "$TEMP_KEY_FILE"
    
    if [[ $? -eq 0 && -s "$TEMP_KEY_FILE" ]]; then
        log_message "Key successfully downloaded. Replacing key in $CONFIG_FILE"
        mv "$TEMP_KEY_FILE" "$CONFIG_FILE"
        # Also save as backup
        cp "$CONFIG_FILE" "$BACKUP_KEY"
    else
        log_message "Error downloading key. Using last available key."
        rm -f "$TEMP_KEY_FILE"
        # Try to use backup if it exists
        if [[ -f "$BACKUP_KEY" ]]; then
            cp "$BACKUP_KEY" "$CONFIG_FILE"
        else
            log_message "No backup key available."
            nvram set vpnc_state_t=0
            exit 1
        fi
    fi
else
    log_message "Server unavailable. Using last available key."
    if [[ -f "$BACKUP_KEY" ]]; then
        cp "$BACKUP_KEY" "$CONFIG_FILE"
    else
        log_message "No backup key available."
        nvram set vpnc_state_t=0
        exit 1
    fi
fi

# 4. Start OpenVPN
log_message "Starting OpenVPN with configuration $CONFIG_FILE"
/usr/sbin/openvpn --config "$CONFIG_FILE"

if [[ $? -eq 0 ]]; then
    log_message "OpenVPN successfully started."
    nvram set vpnc_state_t=1
else
    log_message "Error starting OpenVPN."
    nvram set vpnc_state_t=0
    exit 1
fi

exit 0