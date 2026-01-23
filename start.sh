#!/bin/bash
set -e

DATA_DIR="/app/burp_data"
BURP_JAR="$DATA_DIR/burpsuite_pro.jar"
LOG_FILE="$DATA_DIR/startup.log"
VNC_PASSWORD="${VNC_PASSWORD:-$(openssl rand -base64 12)}"

mkdir -p "$DATA_DIR" "$HOME/.vnc" /var/log

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG_FILE"
}

if [ ! -f "$BURP_JAR" ]; then
    log "Downloading Burp Suite Professional (first run)..."
    wget -q --show-progress -O "$BURP_JAR" \
        "https://portswigger.net/burp/releases/download?product=pro&type=Jar" || {
        log "ERROR: Failed to download Burp Suite!"
        exit 1
    }
    log "Burp Suite downloaded successfully"
else
    log "Burp Suite already downloaded"
fi

log "Starting VNC server..."
vncserver -kill :1 2>/dev/null || true
sleep 1

VNC_AUTH="${VNC_AUTH:-false}"

if [ "$VNC_AUTH" = "true" ] || [ "$VNC_AUTH" = "yes" ] || [ "$VNC_AUTH" = "1" ]; then
    log "Setting up VNC with password authentication..."
    mkdir -p "$HOME/.vnc"
    echo "$VNC_PASSWORD" | vncpasswd -f > "$HOME/.vnc/passwd" || {
        log "ERROR: Failed to set VNC password"
        exit 1
    }
    chmod 600 "$HOME/.vnc/passwd"
    log "VNC password configured"
    echo "=========================================" >&2
    echo "VNC PASSWORD: $VNC_PASSWORD" >&2
    echo "=========================================" >&2
    
    VNC_OPTS="-SecurityTypes VncAuth -PasswordFile $HOME/.vnc/passwd"
else
    log "VNC authentication disabled (no password required)"
    VNC_OPTS="-SecurityTypes None --I-KNOW-THIS-IS-INSECURE"
fi

log "Starting VNC server..."
vncserver :1 -geometry 1920x1080 -depth 24 \
    -localhost no \
    $VNC_OPTS \
    2>&1 | tee -a "$LOG_FILE" || {
    log "ERROR: VNC server command failed"
    exit 1
}
sleep 3

if ! pgrep -f "Xtigervnc" > /dev/null && ! pgrep -f "vncserver" > /dev/null; then
    log "ERROR: VNC process not found after startup"
    log "Checking for VNC processes..."
    ps aux | grep -i vnc | tee -a "$LOG_FILE" || true
    log "Checking VNC log files..."
    ls -la "$HOME/.vnc/" | tee -a "$LOG_FILE" || true
    for logfile in "$HOME/.vnc/"*:*.log; do
        [ -f "$logfile" ] && cat "$logfile" | tee -a "$LOG_FILE"
    done
    exit 1
fi
log "VNC started on :1 (auth: $VNC_AUTH)"

export DISPLAY=:1

if [ ! -f "$DATA_DIR/license_key.txt" ]; then
    log "Generating license key..."
    LICENSE_KEY=$(java -cp /app/loader.jar Keygen "${LICENSE_NAME:-User}" 2>/dev/null | tr -d '\r\n')
    if [ -n "$LICENSE_KEY" ]; then
        echo "$LICENSE_KEY" > "$DATA_DIR/license_key.txt"
        chmod 600 "$DATA_DIR/license_key.txt"
        log "License key saved"
    fi
fi

if [ -f "$DATA_DIR/license_key.txt" ]; then
    echo "" >&2
    echo "=========================================" >&2
    echo "LICENSE KEY:" >&2
    echo "=========================================" >&2
    cat "$DATA_DIR/license_key.txt" >&2
    echo "" >&2
    echo "=========================================" >&2
    echo "ACTIVATION:" >&2
    echo "1. VNC: localhost:5901" >&2
    echo "2. Paste license key" >&2
    echo "3. Manual activation → Next" >&2
    echo "4. Copy Request, run:" >&2
    echo "   docker compose exec burpsuite java -cp /app/loader.jar Keygen -activate \"<REQUEST>\"" >&2
    echo "5. Paste Response → Next" >&2
    echo "=========================================" >&2
    echo "" >&2
fi

if [ ! -f "$DATA_DIR/burp_user_config.json" ]; then
    echo "{}" > "$DATA_DIR/burp_user_config.json"
    log "Created default user config file"
fi
if [ ! -f "$DATA_DIR/burp_config.json" ]; then
    echo "{}" > "$DATA_DIR/burp_config.json"
    log "Created default config file"
fi

log "Starting Burp Suite..."
exec java $JAVA_OPTS -jar "$BURP_JAR" \
    --project-file="$DATA_DIR/burp_project.burp" \
    --config-file="$DATA_DIR/burp_config.json" \
    --user-config-file="$DATA_DIR/burp_user_config.json" \
    2>&1 | tee -a "$DATA_DIR/burp.log"
