#!/bin/bash
# Start code-server and configure nginx reverse proxy

CODE_SERVER_BIN="/usr/local/bin/code-server"
CODE_SERVER_LOG="/var/log/code-server.log"
WORKSPACE="/root"
DATA_DIR="/mnt/pool/appdata/code-server/data"
NGINX_LOCATIONS="/etc/nginx/conf.d/locations.conf"

# Unset VS Code env variables that interfere
unset VSCODE_IPC_HOOK_CLI
unset VSCODE_GIT_ASKPASS_NODE
unset VSCODE_GIT_ASKPASS_MAIN

# 1. Start code-server
if pgrep -f "lib/node.*code-server-4" > /dev/null; then
    echo "code-server already running (PID: $(pgrep -f 'lib/node.*code-server-4'))"
else
    mkdir -p "$DATA_DIR"
    echo "Starting code-server on port 8443..."
    nohup env -i HOME="$HOME" PATH="$PATH" "$CODE_SERVER_BIN" "$WORKSPACE" > "$CODE_SERVER_LOG" 2>&1 &
    sleep 3
    
    if netstat -tlnp 2>/dev/null | grep -q :8443; then
        echo "code-server started successfully"
    else
        echo "WARNING: code-server may have failed to start. Check $CODE_SERVER_LOG"
    fi
fi

# 2. Configure nginx reverse proxy
if ! grep -q "location ^~ /vscode-server/" "$NGINX_LOCATIONS" 2>/dev/null; then
    cat >> "$NGINX_LOCATIONS" << 'NGINXEOF'

# Code-server reverse proxy
location ^~ /vscode-server/ {
    satisfy any;
    allow all;
    auth_request off;
    proxy_pass http://127.0.0.1:8443/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # Timeouts
    proxy_connect_timeout 60s;
    proxy_send_timeout 86400;
    proxy_read_timeout 86400;
    
    # Disable buffering for better streaming
    proxy_buffering off;
    proxy_request_buffering off;
    
    # Handle large files
    proxy_max_temp_file_size 0;
    client_max_body_size 0;
    
    # Chunked transfer encoding fix
    chunked_transfer_encoding on;
}
NGINXEOF
    echo "Added code-server location to nginx"
fi

# 3. Reload nginx
if pgrep nginx > /dev/null; then
    nginx -s reload 2>/dev/null && echo "Nginx reloaded with code-server proxy"
fi
