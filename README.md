# DevOps Tools Container

A secure, locked-down Docker container with **asdf** version management for DevOps and Infrastructure-as-Code tools.

## Included Tools

| Tool | Latest | Previous | Purpose |
|------|--------|----------|---------|
| **Terraform** | 1.13.0 | 1.12.2 | Infrastructure as Code |
| **Python** | 3.13.7 | 3.12.8 | Scripting, Ansible |
| **Node.js** | 22.11.0 | 20.18.0 | JavaScript runtime, npm |
| **Rust** | 1.91.1 | 1.90.0 | Systems programming |
| **kubectl** | 1.34.0 | 1.33.0 | Kubernetes CLI |
| **Helm** | 3.19.2 | 3.18.3 | Kubernetes package manager |
| **Go** | 1.23.4 | 1.22.10 | Cloud tooling |
| **Packer** | 1.11.2 | 1.10.3 | Image building |

### Python Packages
- ansible-core, ansible-lint
- awscli, azure-cli, boto3
- pre-commit, yamllint, checkov

### Node.js Packages
- npm, yarn, typescript, cdktf-cli

### System Tools
- jq, yq, git, curl, wget, openssh-client

## Quick Start

### Build the Container

```bash
# Standard build
docker build -t devtools:latest .

# Build with custom versions
docker build -t devtools:latest \
  --build-arg TERRAFORM_LATEST=1.13.0 \
  --build-arg PYTHON_LATEST=3.13.7 \
  .
```

### Run Interactively

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
├── Dockerfile           # Main container definition
├── docker-compose.yml   # Compose configuration
├── README.md           # This file
└── workspace/          # Your project files (mounted)
```

## License

MIT License - Use freely for your DevOps workflows.
# devtools-container
