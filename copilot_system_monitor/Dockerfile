# VS Code Monitor
# AI-powered container that monitors system health using GitHub Copilot CLI

FROM node:22-slim

# Install dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y \
    curl \
    jq \
    git \
    python3 \
    docker.io \
    util-linux \
    libvirt-clients \
    smartmontools \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub Copilot CLI
ARG COPILOT_VERSION=latest
RUN --mount=type=cache,target=/root/.npm \
    npm install -g @github/copilot@${COPILOT_VERSION}

# Configure git
RUN git config --global --add safe.directory '*' && \
    git config --global credential.helper '!f() { echo "username=x-access-token"; echo "password=$GH_TOKEN"; }; f'

# Create directories
WORKDIR /app
RUN mkdir -p /app/logs /state/analysis

# Copy monitoring scripts
COPY system_monitor.py /app/
COPY copilot_prompt.md /app/
COPY system_info.py /app/
COPY send_alert.sh /usr/local/bin/send_alert
COPY alert_helper.py /app/
COPY host_cmd.sh /usr/local/bin/host_cmd
RUN chmod +x /usr/local/bin/send_alert /usr/local/bin/host_cmd

# Default command
CMD ["python3", "/app/system_monitor.py"]
