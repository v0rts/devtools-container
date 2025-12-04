# =============================================================================
# Secure DevOps Tools Container with asdf Version Management
# =============================================================================
# Base: Ubuntu 24.04 LTS (Noble Numbat) - minimal and security-focused
# Purpose: Locked-down container for infrastructure/DevOps tooling
# =============================================================================

FROM ubuntu:24.04 AS base

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Labels for container metadata
LABEL maintainer="DevOps Team"
LABEL description="Secure DevOps tools container with asdf version management"
LABEL version="1.0.0"

# =============================================================================
# Security: Create non-root user early
# =============================================================================
ARG USERNAME=tooluser
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN set -e; \
    # Get existing user at UID if exists \
    EXISTING_USER=$(getent passwd ${USER_UID} | cut -d: -f1 || echo ""); \
    \
    # If user with this UID exists and it's not our username, delete it \
    if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "${USERNAME}" ]; then \
        userdel -r "$EXISTING_USER" 2>/dev/null || true; \
    fi; \
    \
    # Ensure group exists (check AFTER potential user deletion) \
    if ! getent group ${USER_GID} >/dev/null 2>&1; then \
        groupadd --gid ${USER_GID} ${USERNAME}; \
    fi; \
    \
    # Create user if it doesn't exist \
    if ! id -u ${USERNAME} >/dev/null 2>&1; then \
        useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME}; \
    fi; \
    \
    mkdir -p /home/${USERNAME}/.local/bin; \
    chown -R ${USERNAME}:${USER_GID} /home/${USERNAME}

# =============================================================================
# Install System Dependencies
# =============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Essential build tools
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    # SSL/TLS and crypto
    libssl-dev \
    ca-certificates \
    # Compression
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libzstd-dev \
    # Python dependencies
    libffi-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncursesw5-dev \
    libxml2-dev \
    libxmlsec1-dev \
    tk-dev \
    # Version control
    git \
    # Network tools
    curl \
    wget \
    # Utilities
    unzip \
    jq \
    xz-utils \
    # Shell
    bash \
    bash-completion \
    # SSH client (for git/ansible)
    openssh-client \
    # Required for some asdf plugins
    dirmngr \
    gpg \
    gpg-agent \
    gawk \
    # Cleanup
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# =============================================================================
# Install yq (YAML processor) - system-wide
# =============================================================================
ARG YQ_VERSION=v4.44.3
RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" \
    -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# =============================================================================
# Switch to non-root user for remaining setup
# =============================================================================
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# =============================================================================
# Install asdf Version Manager
# =============================================================================
ARG ASDF_VERSION=v0.15.0
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch ${ASDF_VERSION}

# Configure shell for asdf
RUN echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc \
    && echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc

# Set up asdf environment for build
ENV ASDF_DIR="/home/${USERNAME}/.asdf"
ENV PATH="${ASDF_DIR}/bin:${ASDF_DIR}/shims:${PATH}"

# =============================================================================
# Tool Version Configuration
# =============================================================================
# Define versions as build arguments for easy updates
# Latest versions
ARG TERRAFORM_LATEST=1.13.0
ARG TERRAFORM_PREV=1.12.2

ARG PYTHON_LATEST=3.13.7
ARG PYTHON_PREV=3.12.8

ARG NODEJS_LATEST=22.11.0
ARG NODEJS_PREV=20.18.0

ARG RUST_LATEST=1.91.1
ARG RUST_PREV=1.90.0

ARG KUBECTL_LATEST=1.34.0
ARG KUBECTL_PREV=1.33.0

ARG HELM_LATEST=3.19.2
ARG HELM_PREV=3.18.3

ARG GOLANG_LATEST=1.23.4
ARG GOLANG_PREV=1.22.10

ARG PACKER_LATEST=1.11.2
ARG PACKER_PREV=1.10.3

# =============================================================================
# Install asdf Plugins
# =============================================================================
RUN asdf plugin add terraform https://github.com/asdf-community/asdf-hashicorp.git \
    && asdf plugin add python https://github.com/asdf-community/asdf-python.git \
    && asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git \
    && asdf plugin add rust https://github.com/asdf-community/asdf-rust.git \
    && asdf plugin add kubectl https://github.com/asdf-community/asdf-kubectl.git \
    && asdf plugin add helm https://github.com/Antiarchitect/asdf-helm.git \
    && asdf plugin add golang https://github.com/asdf-community/asdf-golang.git \
    && asdf plugin add packer https://github.com/asdf-community/asdf-hashicorp.git

# =============================================================================
# Install Tool Versions
# =============================================================================

# Option to skip previous versions (saves ~40% space)
ARG INSTALL_PREV_VERSIONS=true

# Terraform
RUN asdf install terraform ${TERRAFORM_LATEST} \
    && if [ "$INSTALL_PREV_VERSIONS" = "true" ]; then asdf install terraform ${TERRAFORM_PREV}; fi \
    && asdf global terraform ${TERRAFORM_LATEST} \
    && rm -rf ~/.asdf/downloads/*

# Python (takes a while to compile)
RUN asdf install python ${PYTHON_LATEST} \
    && if [ "$INSTALL_PREV_VERSIONS" = "true" ]; then asdf install python ${PYTHON_PREV}; fi \
    && asdf global python ${PYTHON_LATEST} \
    && rm -rf ~/.asdf/downloads/* \
    && find ~/.asdf/installs/python -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

# Node.js
RUN asdf install nodejs ${NODEJS_LATEST} \
    && if [ "$INSTALL_PREV_VERSIONS" = "true" ]; then asdf install nodejs ${NODEJS_PREV}; fi \
    && asdf global nodejs ${NODEJS_LATEST} \
    && rm -rf ~/.asdf/downloads/* \
    && npm cache clean --force

# Rust
RUN asdf install rust ${RUST_LATEST} \
    && if [ "$INSTALL_PREV_VERSIONS" = "true" ]; then asdf install rust ${RUST_PREV}; fi \
    && asdf global rust ${RUST_LATEST} \
    && rm -rf ~/.asdf/downloads/*

# kubectl
RUN asdf install kubectl ${KUBECTL_LATEST} \
    && if [ "$INSTALL_PREV_VERSIONS" = "true" ]; then asdf install kubectl ${KUBECTL_PREV}; fi \
    && asdf global kubectl ${KUBECTL_LATEST} \
    && rm -rf ~/.asdf/downloads/*

# Helm
RUN asdf install helm ${HELM_LATEST} \
    && if [ "$INSTALL_PREV_VERSIONS" = "true" ]; then asdf install helm ${HELM_PREV}; fi \
    && asdf global helm ${HELM_LATEST} \
    && rm -rf ~/.asdf/downloads/*

# Go
RUN asdf install golang ${GOLANG_LATEST} \
    && if [ "$INSTALL_PREV_VERSIONS" = "true" ]; then asdf install golang ${GOLANG_PREV}; fi \
    && asdf global golang ${GOLANG_LATEST} \
    && rm -rf ~/.asdf/downloads/* \
    && go clean -cache -modcache 2>/dev/null || true

# Packer
RUN asdf install packer ${PACKER_LATEST} \
    && if [ "$INSTALL_PREV_VERSIONS" = "true" ]; then asdf install packer ${PACKER_PREV}; fi \
    && asdf global packer ${PACKER_LATEST} \
    && rm -rf ~/.asdf/downloads/*

# =============================================================================
# Install Python-based Tools (Ansible, AWS CLI, etc.)
# =============================================================================
# Ensure pip is up to date and install tools
RUN pip install --upgrade pip --no-cache-dir \
    && pip install --no-cache-dir \
    ansible-core==2.18.1 \
    ansible-lint \
    awscli \
    azure-cli \
    boto3 \
    pre-commit \
    yamllint \
    checkov \
    # Clean up __pycache__ and bytecode only (preserve test modules for ansible)
    && find ~/.asdf/installs/python -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true \
    && find ~/.asdf/installs/python -type f -name "*.pyc" -delete 2>/dev/null || true \
    && find ~/.asdf/installs/python -type f -name "*.pyo" -delete 2>/dev/null || true \
    # Selectively remove large test suites (but NOT ansible.plugins.test)
    && rm -rf ~/.asdf/installs/python/*/lib/python*/site-packages/numpy/*/tests 2>/dev/null || true \
    && rm -rf ~/.asdf/installs/python/*/lib/python*/site-packages/scipy/*/tests 2>/dev/null || true \
    && rm -rf ~/.asdf/installs/python/*/lib/python*/site-packages/pandas/tests 2>/dev/null || true

# =============================================================================
# Install Node.js-based Tools
# =============================================================================
RUN npm install -g --no-fund --no-audit \
    npm@latest \
    yarn \
    typescript \
    cdktf-cli

# =============================================================================
# Create .tool-versions file for project-level version management
# =============================================================================
RUN echo "terraform ${TERRAFORM_LATEST}" > ~/.tool-versions \
    && echo "python ${PYTHON_LATEST}" >> ~/.tool-versions \
    && echo "nodejs ${NODEJS_LATEST}" >> ~/.tool-versions \
    && echo "rust ${RUST_LATEST}" >> ~/.tool-versions \
    && echo "kubectl ${KUBECTL_LATEST}" >> ~/.tool-versions \
    && echo "helm ${HELM_LATEST}" >> ~/.tool-versions \
    && echo "golang ${GOLANG_LATEST}" >> ~/.tool-versions \
    && echo "packer ${PACKER_LATEST}" >> ~/.tool-versions

# =============================================================================
# Security Hardening
# =============================================================================
# Create workspace directory
RUN mkdir -p /home/${USERNAME}/workspace

# Set restrictive umask
RUN echo "umask 027" >> ~/.bashrc

# =============================================================================
# Environment Configuration
# =============================================================================
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV EDITOR=vi
ENV TERM=xterm-256color

# Helpful aliases
RUN echo 'alias ll="ls -alF"' >> ~/.bashrc \
    && echo 'alias tf="terraform"' >> ~/.bashrc \
    && echo 'alias k="kubectl"' >> ~/.bashrc \
    && echo 'alias h="helm"' >> ~/.bashrc \
    && echo 'alias python="python3"' >> ~/.bashrc

# =============================================================================
# Health Check
# =============================================================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD asdf current || exit 1

# =============================================================================
# Default Working Directory and Command
# =============================================================================
WORKDIR /home/${USERNAME}/workspace

# Default to bash shell
CMD ["/bin/bash"]

# =============================================================================
# Build Instructions:
# =============================================================================
# Build:
#   docker build -t devtools:latest .
#
# Run interactively:
#   docker run -it --rm -v $(pwd):/home/tooluser/workspace devtools:latest
#
# Run with AWS credentials:
#   docker run -it --rm \
#     -v $(pwd):/home/tooluser/workspace \
#     -v ~/.aws:/home/tooluser/.aws:ro \
#     -e AWS_PROFILE=default \
#     devtools:latest
#
# Run with Kubernetes config:
#   docker run -it --rm \
#     -v $(pwd):/home/tooluser/workspace \
#     -v ~/.kube:/home/tooluser/.kube:ro \
#     devtools:latest
# =============================================================================
