#!/bin/bash
# Create nginx reverse proxy config for code-server

NGINX_LOCATIONS="/etc/nginx/conf.d/locations.conf"

# Check if code-server location already exists
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

# Reload nginx if running
if pgrep nginx > /dev/null; then
    nginx -s reload 2>/dev/null && echo "Nginx reloaded with code-server proxy"
fi
