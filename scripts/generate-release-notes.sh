#!/bin/bash
# =============================================================================
# Release Notes Generator
# =============================================================================
# Extracts version information from Dockerfile and generates release notes
# from the template.
#
# Usage:
#   ./scripts/generate-release-notes.sh <version> [previous-version]
#
# Example:
#   ./scripts/generate-release-notes.sh 1.0.0 0.9.0
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check arguments
if [ -z "$1" ]; then
    log_error "Version number required"
    echo "Usage: $0 <version> [previous-version]"
    echo "Example: $0 1.0.0 0.9.0"
    exit 1
fi

VERSION=$1
PREVIOUS=${2:-""}
DOCKERFILE="Dockerfile"
TEMPLATE=".github/release-template.md"
OUTPUT="release-notes-v${VERSION}.md"

# Check if files exist
if [ ! -f "$DOCKERFILE" ]; then
    log_error "Dockerfile not found at: $DOCKERFILE"
    exit 1
fi

if [ ! -f "$TEMPLATE" ]; then
    log_error "Release template not found at: $TEMPLATE"
    exit 1
fi

log_info "Extracting version information from Dockerfile..."

# Extract version ARGs from Dockerfile
extract_version() {
    local arg_name=$1
    grep "ARG ${arg_name}=" "$DOCKERFILE" | cut -d'=' -f2 || echo "unknown"
}

TERRAFORM_LATEST=$(extract_version "TERRAFORM_LATEST")
TERRAFORM_PREV=$(extract_version "TERRAFORM_PREV")

PYTHON_LATEST=$(extract_version "PYTHON_LATEST")
PYTHON_PREV=$(extract_version "PYTHON_PREV")

NODEJS_LATEST=$(extract_version "NODEJS_LATEST")
NODEJS_PREV=$(extract_version "NODEJS_PREV")

RUST_LATEST=$(extract_version "RUST_LATEST")
RUST_PREV=$(extract_version "RUST_PREV")

KUBECTL_LATEST=$(extract_version "KUBECTL_LATEST")
KUBECTL_PREV=$(extract_version "KUBECTL_PREV")

HELM_LATEST=$(extract_version "HELM_LATEST")
HELM_PREV=$(extract_version "HELM_PREV")

GOLANG_LATEST=$(extract_version "GOLANG_LATEST")
GOLANG_PREV=$(extract_version "GOLANG_PREV")

PACKER_LATEST=$(extract_version "PACKER_LATEST")
PACKER_PREV=$(extract_version "PACKER_PREV")

log_info "Found versions:"
echo "  Terraform: $TERRAFORM_LATEST, $TERRAFORM_PREV"
echo "  Python: $PYTHON_LATEST, $PYTHON_PREV"
echo "  Node.js: $NODEJS_LATEST, $NODEJS_PREV"
echo "  Rust: $RUST_LATEST, $RUST_PREV"
echo "  kubectl: $KUBECTL_LATEST, $KUBECTL_PREV"
echo "  Helm: $HELM_LATEST, $HELM_PREV"
echo "  Go: $GOLANG_LATEST, $GOLANG_PREV"
echo "  Packer: $PACKER_LATEST, $PACKER_PREV"

log_info "Generating release notes from template..."

# Generate release notes from template
sed -e "s/{VERSION}/$VERSION/g" \
    -e "s/{PREVIOUS}/$PREVIOUS/g" \
    -e "s/{TERRAFORM_LATEST}/$TERRAFORM_LATEST/g" \
    -e "s/{TERRAFORM_PREV}/$TERRAFORM_PREV/g" \
    -e "s/{PYTHON_LATEST}/$PYTHON_LATEST/g" \
    -e "s/{PYTHON_PREV}/$PYTHON_PREV/g" \
    -e "s/{NODEJS_LATEST}/$NODEJS_LATEST/g" \
    -e "s/{NODEJS_PREV}/$NODEJS_PREV/g" \
    -e "s/{RUST_LATEST}/$RUST_LATEST/g" \
    -e "s/{RUST_PREV}/$RUST_PREV/g" \
    -e "s/{KUBECTL_LATEST}/$KUBECTL_LATEST/g" \
    -e "s/{KUBECTL_PREV}/$KUBECTL_PREV/g" \
    -e "s/{HELM_LATEST}/$HELM_LATEST/g" \
    -e "s/{HELM_PREV}/$HELM_PREV/g" \
    -e "s/{GOLANG_LATEST}/$GOLANG_LATEST/g" \
    -e "s/{GOLANG_PREV}/$GOLANG_PREV/g" \
    -e "s/{PACKER_LATEST}/$PACKER_LATEST/g" \
    -e "s/{PACKER_PREV}/$PACKER_PREV/g" \
    "$TEMPLATE" > "$OUTPUT"

log_info "Release notes generated: $OUTPUT"
log_info ""
log_info "Next steps:"
echo "  1. Review the generated release notes: cat $OUTPUT"
echo "  2. Edit to add 'What's New' and 'Breaking Changes'"
echo "  3. Create GitHub release:"
echo "     gh release create v${VERSION} --title \"DevTools Container v${VERSION}\" --notes-file $OUTPUT"
echo "  4. Or create draft release:"
echo "     gh release create v${VERSION} --draft --title \"DevTools Container v${VERSION}\" --notes-file $OUTPUT"

log_info ""
log_info "Done! 🚀"
