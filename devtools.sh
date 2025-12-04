#!/bin/bash
# =============================================================================
# DevTools Container Runner Script
# =============================================================================
set -e

CONTAINER_NAME="devtools"
IMAGE_NAME="devtools:latest"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(pwd)}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Usage: $(basename "$0") [command] [options]

Commands:
    build       Build the container image
    build-slim  Build smaller image (skip previous versions, ~40% smaller)
    run         Run the container interactively (default)
    exec        Execute a command in running container
    shell       Start a shell in running container
    versions    Show installed tool versions
    stop        Stop the running container
    clean       Remove container and volumes

Options:
    -h, --help  Show this help message

Environment Variables:
    WORKSPACE_DIR   Directory to mount as workspace (default: current directory)
    AWS_PROFILE     AWS profile to use (default: default)
    AWS_REGION      AWS region (default: us-east-1)

Examples:
    $(basename "$0") build
    $(basename "$0") run
    $(basename "$0") exec terraform --version
    WORKSPACE_DIR=/path/to/project $(basename "$0") run
EOF
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

build() {
    log_info "Building ${IMAGE_NAME}..."
    docker build -t "${IMAGE_NAME}" "$(dirname "$0")"
    log_info "Build complete!"
}

build_slim() {
    log_info "Building ${IMAGE_NAME} (slim - no previous versions)..."
    docker build -t "${IMAGE_NAME}" \
        --build-arg INSTALL_PREV_VERSIONS=false \
        "$(dirname "$0")"
    log_info "Slim build complete! (~40% smaller than full build)"
}

run_container() {
    log_info "Starting ${CONTAINER_NAME} container..."
    log_info "Workspace: ${WORKSPACE_DIR}"
    
    local mounts=()
    
    # Always mount workspace
    mounts+=("-v" "${WORKSPACE_DIR}:/home/tooluser/workspace")
    
    # Optional mounts - only if they exist
    if [[ -d "${HOME}/.aws" ]]; then
        mounts+=("-v" "${HOME}/.aws:/home/tooluser/.aws:ro")
        log_info "Mounting AWS credentials (read-only)"
    fi
    
    if [[ -d "${HOME}/.kube" ]]; then
        mounts+=("-v" "${HOME}/.kube:/home/tooluser/.kube:ro")
        log_info "Mounting Kubernetes config (read-only)"
    fi
    
    if [[ -d "${HOME}/.ssh" ]]; then
        mounts+=("-v" "${HOME}/.ssh:/home/tooluser/.ssh:ro")
        log_info "Mounting SSH keys (read-only)"
    fi
    
    if [[ -f "${HOME}/.gitconfig" ]]; then
        mounts+=("-v" "${HOME}/.gitconfig:/home/tooluser/.gitconfig:ro")
        log_info "Mounting Git config (read-only)"
    fi
    
    docker run -it --rm \
        --name "${CONTAINER_NAME}" \
        --hostname "${CONTAINER_NAME}" \
        --security-opt no-new-privileges:true \
        -e "AWS_PROFILE=${AWS_PROFILE:-default}" \
        -e "AWS_REGION=${AWS_REGION:-us-east-1}" \
        "${mounts[@]}" \
        "${IMAGE_NAME}" \
        "$@"
}

exec_in_container() {
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_error "Container ${CONTAINER_NAME} is not running"
        exit 1
    fi
    docker exec -it "${CONTAINER_NAME}" "$@"
}

show_versions() {
    log_info "Tool versions in container:"
    run_container bash -c '
        echo "=== asdf managed tools ==="
        asdf current 2>/dev/null || true
        echo ""
        echo "=== Additional tools ==="
        echo "ansible-core: $(ansible --version | head -1)"
        echo "aws-cli: $(aws --version 2>&1)"
        echo "jq: $(jq --version)"
        echo "yq: $(yq --version)"
    '
}

stop_container() {
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "Stopping ${CONTAINER_NAME}..."
        docker stop "${CONTAINER_NAME}"
    else
        log_warn "Container ${CONTAINER_NAME} is not running"
    fi
}

clean() {
    stop_container 2>/dev/null || true
    
    log_info "Removing container and volumes..."
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true
    docker volume rm devtools-asdf devtools-pip-cache devtools-npm-cache 2>/dev/null || true
    log_info "Cleanup complete"
}

# Main
case "${1:-run}" in
    build)
        build
        ;;
    build-slim)
        build_slim
        ;;
    run)
        shift 2>/dev/null || true
        run_container "$@"
        ;;
    exec)
        shift
        exec_in_container "$@"
        ;;
    shell)
        exec_in_container bash
        ;;
    versions)
        show_versions
        ;;
    stop)
        stop_container
        ;;
    clean)
        clean
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        log_error "Unknown command: $1"
        usage
        exit 1
        ;;
esac
