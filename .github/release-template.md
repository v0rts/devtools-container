# DevTools Container Release v{VERSION}

Docker images for this release:
- **Docker Hub:** `docker pull v0rts/devtools:{VERSION}`
- **Docker Hub (latest):** `docker pull v0rts/devtools:latest`
- **GHCR:** `docker pull ghcr.io/v0rts/devtools:{VERSION}`
- **GHCR (latest):** `docker pull ghcr.io/v0rts/devtools:latest`

## 📦 Installed Tool Versions

| Tool | Version(s) | Notes |
|------|------------|-------|
| **Terraform** | {TERRAFORM_LATEST}, {TERRAFORM_PREV} | Latest + Previous |
| **Python** | {PYTHON_LATEST}, {PYTHON_PREV} | Latest + Previous |
| **Node.js** | {NODEJS_LATEST}, {NODEJS_PREV} | Latest + Previous |
| **Rust** | {RUST_LATEST}, {RUST_PREV} | Latest + Previous |
| **kubectl** | {KUBECTL_LATEST}, {KUBECTL_PREV} | Latest + Previous |
| **Helm** | {HELM_LATEST}, {HELM_PREV} | Latest + Previous |
| **Go** | {GOLANG_LATEST}, {GOLANG_PREV} | Latest + Previous |
| **Packer** | {PACKER_LATEST}, {PACKER_PREV} | Latest + Previous |

### Python Packages
- ansible-core 2.18.1
- ansible-lint (latest)
- awscli (latest)
- azure-cli (latest)
- boto3 (latest)
- pre-commit (latest)
- yamllint (latest)
- checkov (latest)

### Node.js Packages
- npm (latest)
- yarn (latest)
- typescript (latest)
- cdktf-cli (latest)

### System Tools
- asdf v0.15.0
- yq v4.44.3
- jq, git, curl, wget, openssh-client

## 🆕 What's New in This Release

- Initial MVP release with comprehensive DevOps tooling
- Docker Hub and GHCR multi-registry publishing
- Trivy security scanning integration
- CI/CD pipeline support for GitHub Actions, GoCD, and Jenkins

## ⚠️ Breaking Changes

None - initial release

## 🔧 Build Configuration

This release was built with the following arguments:

```bash
docker build -t devtools:{VERSION} \
  --build-arg TERRAFORM_LATEST={TERRAFORM_LATEST} \
  --build-arg TERRAFORM_PREV={TERRAFORM_PREV} \
  --build-arg PYTHON_LATEST={PYTHON_LATEST} \
  --build-arg PYTHON_PREV={PYTHON_PREV} \
  --build-arg NODEJS_LATEST={NODEJS_LATEST} \
  --build-arg NODEJS_PREV={NODEJS_PREV} \
  --build-arg RUST_LATEST={RUST_LATEST} \
  --build-arg RUST_PREV={RUST_PREV} \
  --build-arg KUBECTL_LATEST={KUBECTL_LATEST} \
  --build-arg KUBECTL_PREV={KUBECTL_PREV} \
  --build-arg HELM_LATEST={HELM_LATEST} \
  --build-arg HELM_PREV={HELM_PREV} \
  --build-arg GOLANG_LATEST={GOLANG_LATEST} \
  --build-arg GOLANG_PREV={GOLANG_PREV} \
  --build-arg PACKER_LATEST={PACKER_LATEST} \
  --build-arg PACKER_PREV={PACKER_PREV} \
  .
```

### Slim Build (Latest Versions Only)

```bash
docker build -t devtools:{VERSION}-slim \
  --build-arg INSTALL_PREV_VERSIONS=false \
  .
```

## 📝 Upgrade Notes

For first-time users:
1. Pull the image: `docker pull v0rts/devtools:{VERSION}`
2. Run with workspace mount: `docker run -it --rm -v $(pwd):/home/tooluser/workspace v0rts/devtools:{VERSION}`
3. See [README](https://github.com/v0rts/devtools-container#readme) for advanced usage

## 🔒 Security

- **Base Image:** Ubuntu 24.04 LTS (Noble Numbat)
- **Non-root user:** Container runs as `tooluser` (UID 1000)
- **Security scanning:** Trivy scan results available in workflow artifacts
- **Known vulnerabilities:** See Trivy report artifact for details
- **GPG verification:** Enabled for HashiCorp tools (Terraform, Packer)

### Security Best Practices
- Credentials mounted as read-only
- `--security-opt no-new-privileges:true` enabled
- Minimal package installation
- Regular security updates via automated builds

## 📊 Image Size

- **Full build:** ~4-5GB (includes previous tool versions)
- **Slim build:** ~2.5-3GB (latest versions only, ~40% smaller)

Optimizations applied:
- Removed documentation files from language runtimes
- Cleaned up package caches after installation
- Removed Python test suites (numpy, scipy, pandas)
- Selective cleanup preserving functional modules

## 🐛 Known Issues

None at this time

## 📚 Documentation

- **Main README:** [README.md](https://github.com/v0rts/devtools-container#readme)
- **GitHub Actions Setup:** [GITHUB-ACTIONS-SETUP.md](https://github.com/v0rts/devtools-container/blob/main/Github/GITHUB-ACTIONS-SETUP.md)
- **GoCD Setup:** [GOCD-SETUP.md](https://github.com/v0rts/devtools-container/blob/main/GOCD/GOCD-SETUP.md)
- **Jenkins Setup:** [JENKINS-SETUP.md](https://github.com/v0rts/devtools-container/blob/main/Jenkins/JENKINS-SETUP.md)
- **Workflow Reference:** [workflows/README.md](https://github.com/v0rts/devtools-container/blob/main/.github/workflows/README.md)

## 🚀 Quick Start

### Pull and Run
```bash
# From Docker Hub
docker pull v0rts/devtools:{VERSION}
docker run -it --rm -v $(pwd):/home/tooluser/workspace v0rts/devtools:{VERSION}

# From GHCR
docker pull ghcr.io/v0rts/devtools:{VERSION}
docker run -it --rm -v $(pwd):/home/tooluser/workspace ghcr.io/v0rts/devtools:{VERSION}
```

### Using Helper Script
```bash
git clone https://github.com/v0rts/devtools-container.git
cd devtools-container
./devtools.sh run
```

### With Credentials
```bash
docker run -it --rm \
  -v $(pwd):/home/tooluser/workspace \
  -v ~/.aws:/home/tooluser/.aws:ro \
  -v ~/.kube:/home/tooluser/.kube:ro \
  -v ~/.ssh:/home/tooluser/.ssh:ro \
  v0rts/devtools:{VERSION}
```

## 🔄 Version Management with asdf

Switch between installed versions:
```bash
# List installed versions
asdf list terraform

# Switch globally
asdf global terraform {TERRAFORM_PREV}

# Switch for current directory
asdf local python {PYTHON_PREV}

# Check current versions
asdf current
```

## 📈 CI/CD Integration

This container is designed for CI/CD pipelines:

- **GitHub Actions:** Automated builds, security scans, and multi-registry publishing
- **GoCD:** XML pipeline configuration with manual approval gates
- **Jenkins:** Job DSL with declarative Jenkinsfile and scheduled scans

See documentation links above for setup instructions.

---

**Full Changelog**: [v{PREVIOUS}...v{VERSION}](https://github.com/v0rts/devtools-container/compare/v{PREVIOUS}...v{VERSION})

**Container SHA256**: [Will be populated after build]

**GitHub Actions Build**: [Link to workflow run]

---

💡 **Tip:** Use the slim build (`INSTALL_PREV_VERSIONS=false`) for CI/CD environments to save disk space and reduce build times!
