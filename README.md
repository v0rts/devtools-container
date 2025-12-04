# DevOps Tools Container

![Latest Release](https://img.shields.io/github/v/release/v0rts/devtools-container)
![Build Status](https://github.com/v0rts/devtools-container/actions/workflows/build.yml/badge.svg)

A secure, locked-down Docker container with **asdf** version management for DevOps and Infrastructure-as-Code tools.

**Pre-built images available:**
- Docker Hub: `v0rts/devtools:latest`
- GitHub Container Registry: `ghcr.io/v0rts/devtools:latest`

**CI/CD Pipelines:**
- ✅ GitHub Actions (automated builds, security scans, multi-registry publishing)
- ✅ GoCD (XML-based pipeline configuration)
- ✅ Jenkins (Job DSL with declarative Jenkinsfile)

## Included Tools

| Tool | Purpose |
|------|---------|
| **Terraform** | Infrastructure as Code |
| **Python** | Scripting, Ansible |
| **Node.js** | JavaScript runtime, npm |
| **Rust** | Systems programming |
| **kubectl** | Kubernetes CLI |
| **Helm** | Kubernetes package manager |
| **Go** | Cloud tooling |
| **Packer** | Image building |

**Version Information:** Each tool includes both latest and previous versions. See [Releases](https://github.com/v0rts/devtools-container/releases) for specific versions in each container release.

### Python Packages
- ansible-core, ansible-lint
- awscli, azure-cli, boto3
- pre-commit, yamllint, checkov

### Node.js Packages
- npm, yarn, typescript, cdktf-cli

### System Tools
- jq, yq, git, curl, wget, openssh-client

## Quick Start

### Pull Pre-Built Image

#### From Docker Hub
```bash
# Pull latest
docker pull v0rts/devtools:latest

# Run
docker run -it --rm -v $(pwd):/home/tooluser/workspace v0rts/devtools:latest
```

#### From GitHub Container Registry
```bash
# Pull latest
docker pull ghcr.io/v0rts/devtools:latest

# Run
docker run -it --rm -v $(pwd):/home/tooluser/workspace ghcr.io/v0rts/devtools:latest
```

### Build the Container

**Using the helper script:**
```bash
# Full build (includes previous versions)
./devtools.sh build

# Slim build (latest versions only, ~40% smaller)
./devtools.sh build-slim
```

**Using Docker directly:**
```bash
# Standard build
docker build -t devtools:latest .

# Slim build (skip previous versions)
docker build -t devtools:latest --build-arg INSTALL_PREV_VERSIONS=false .

# Build with custom versions (see Dockerfile for available build args)
docker build -t devtools:latest \
  --build-arg TERRAFORM_LATEST=<version> \
  --build-arg PYTHON_LATEST=<version> \
  .
```

### Run Interactively

**Using the helper script:**
```bash
# Run with workspace mount and auto-detected credentials
./devtools.sh run

# Check installed versions
./devtools.sh versions

# Execute a single command
./devtools.sh exec terraform version

# Stop running container
./devtools.sh stop

# Clean up container and volumes
./devtools.sh clean
```

**Using Docker directly:**
```bash
# Basic usage
docker run -it --rm \
  -v $(pwd):/home/tooluser/workspace \
  devtools:latest

# With AWS and Kubernetes credentials
docker run -it --rm \
  -v $(pwd):/home/tooluser/workspace \
  -v ~/.aws:/home/tooluser/.aws:ro \
  -v ~/.kube:/home/tooluser/.kube:ro \
  -v ~/.ssh:/home/tooluser/.ssh:ro \
  -e AWS_PROFILE=default \
  devtools:latest
```

### Using Docker Compose

```bash
# Build and start
docker-compose up -d --build

# Attach to running container
docker-compose exec devtools bash

# Stop
docker-compose down
```

## Version Management with asdf

### Switch Tool Versions

```bash
# List installed versions
asdf list terraform

# Switch globally
asdf global terraform 1.12.2

# Switch for current directory only
asdf local terraform 1.12.2

# Check current versions
asdf current
```

### Install Additional Versions

```bash
# List available versions
asdf list-all terraform

# Install a specific version
asdf install terraform 1.11.4

# Install latest
asdf install terraform latest
```

### Project-Level Versions

Create a `.tool-versions` file in your project:

```
terraform 1.12.2
python 3.12.8
nodejs 20.18.0
```

asdf will automatically use these versions when you're in that directory.

## Security Features

- **Non-root user**: Runs as `tooluser` (UID 1000)
- **Read-only mounts**: Credentials mounted as read-only
- **No new privileges**: Security option enabled
- **Minimal base image**: Ubuntu 24.04 minimal
- **Resource limits**: CPU and memory constraints in docker-compose

## Customization

### Adding New Tools

1. Add the asdf plugin in the Dockerfile:
```dockerfile
RUN asdf plugin add <tool> <plugin-url>
```

2. Install versions:
```dockerfile
ARG TOOL_LATEST=x.y.z
ARG TOOL_PREV=x.y.z
RUN asdf install <tool> ${TOOL_LATEST} \
    && asdf install <tool> ${TOOL_PREV} \
    && asdf global <tool> ${TOOL_LATEST}
```

### Common asdf Plugins

| Tool | Plugin URL |
|------|------------|
| terraform | https://github.com/asdf-community/asdf-hashicorp.git |
| python | https://github.com/asdf-community/asdf-python.git |
| nodejs | https://github.com/asdf-vm/asdf-nodejs.git |
| rust | https://github.com/asdf-community/asdf-rust.git |
| kubectl | https://github.com/asdf-community/asdf-kubectl.git |
| helm | https://github.com/Antiarchitect/asdf-helm.git |
| golang | https://github.com/asdf-community/asdf-golang.git |
| aws-cli | https://github.com/MetricMike/asdf-awscli.git |
| gcloud | https://github.com/jthegedus/asdf-gcloud.git |
| vault | https://github.com/asdf-community/asdf-hashicorp.git |

## Updating Versions

1. Check latest versions:
   - https://endoflife.date/terraform
   - https://endoflife.date/python
   - https://endoflife.date/nodejs
   - https://releases.rs (Rust)

2. Update version ARGs in Dockerfile

3. Rebuild:
```bash
docker build --no-cache -t devtools:latest .
```

## Troubleshooting

### asdf command not found
```bash
source ~/.bashrc
# or
. $HOME/.asdf/asdf.sh
```

### Python build fails
Ensure all build dependencies are installed. The Dockerfile includes common ones, but some packages may need additional libraries.

### Slow build times
Python and Rust compile from source. Consider using a multi-stage build or pre-built binaries for faster builds.

### Permission denied on mounted volumes
Ensure your host UID matches the container user (1000). Or rebuild with your UID:
```bash
docker build --build-arg USER_UID=$(id -u) -t devtools:latest .
```

## Directory Structure

```
devtools-container/
├── Dockerfile                        # Main container definition
├── devtools.sh                       # Helper script for build/run
├── docker-compose.yml                # Compose configuration
├── README.md                         # This file
├── .github/
│   └── workflows/
│       ├── build.yml                 # GitHub Actions pipeline
│       └── README.md                 # Workflow documentation
├── GOCD/
│   ├── gocd-pipeline.xml             # GoCD pipeline config
│   └── GOCD-SETUP.md                 # GoCD setup guide
├── Jenkins/
│   ├── devtools-pipeline.groovy      # Jenkins Job DSL
│   ├── Jenkinsfile                   # Declarative pipeline
│   ├── JENKINS-SETUP.md              # Jenkins setup guide
│   └── README.md                     # Quick reference
├── Github/
│   └── GITHUB-ACTIONS-SETUP.md       # GitHub Actions setup guide
└── workspace/                        # Your project files (mounted)
```

## License

MIT License - Use freely for your DevOps workflows.

## Additional Documentation

- **GitHub Actions Setup:** [Github/GITHUB-ACTIONS-SETUP.md](Github/GITHUB-ACTIONS-SETUP.md)
- **GoCD Setup:** [GOCD/GOCD-SETUP.md](GOCD/GOCD-SETUP.md)
- **Jenkins Setup:** [Jenkins/JENKINS-SETUP.md](Jenkins/JENKINS-SETUP.md)
- **Workflow Reference:** [.github/workflows/README.md](.github/workflows/README.md)
