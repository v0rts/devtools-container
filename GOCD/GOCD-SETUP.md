# GoCD Pipeline Setup Guide

This guide explains how to configure the GoCD pipeline for the DevTools Container project.

## Pipeline Overview

The pipeline consists of 4 stages:

1. **Build** - Builds the Docker image and tags it with the pipeline label
2. **Security-Scan** - Runs Trivy security scanner to detect vulnerabilities
3. **Verify** - Runs smoke tests to ensure the image works correctly
4. **Cleanup** - (Manual approval) Removes old images to save disk space

## Prerequisites

### On GoCD Agents

Ensure your GoCD agents have the following installed:

- Docker (for building and running containers)
- curl (for installing Trivy)
- bash

### Optional: Pre-install Trivy

To speed up builds, pre-install Trivy on your GoCD agents:

```bash
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
```

## Setup Instructions

### Option 1: Using GoCD UI

1. Log in to your GoCD server
2. Navigate to **Admin** > **Pipelines**
3. Click **Create a new pipeline**
4. Fill in the pipeline details:
   - **Pipeline Name**: `devtools-container`
   - **Material Type**: Git
   - **URL**: Your repository URL
5. Click through the wizard and then switch to **Config XML** tab
6. Copy the contents of `gocd-pipeline.xml` into the configuration
7. Save the pipeline

### Option 2: Using Configuration Repository

1. Add this repository as a GoCD configuration repository:
   - Go to **Admin** > **Config Repositories**
   - Add a new config repo pointing to your repository
   - Ensure the XML is in the proper format for your GoCD version

### Option 3: Manual Configuration File

1. Locate your GoCD `cruise-config.xml` file (typically in `/etc/go` or `C:\Program Files\Go Server\config`)
2. Add the pipeline configuration from `gocd-pipeline.xml` inside the `<pipelines>` section
3. Restart GoCD server or trigger a config reload

## Configuration Customization

### Update Git Repository URL

Edit line 17 in `gocd-pipeline.xml`:

```xml
<git url="https://github.com/your-org/devtools-container.git" dest="devtools" materialName="devtools-repo">
```

Replace with your actual repository URL.

### Adjust Security Scan Severity

To change which vulnerabilities fail the build, edit the `--severity` argument in the Security-Scan stage:

```xml
<arg>--severity</arg>
<arg>HIGH,CRITICAL</arg>  <!-- Change to LOW,MEDIUM,HIGH,CRITICAL if needed -->
```

### Modify Cleanup Retention

To keep more or fewer old images, edit line in the Cleanup stage:

```xml
<arg>docker images devtools --format "{{.ID}}" | tail -n +6 | xargs -r docker rmi -f || true</arg>
```

Change `tail -n +6` to `tail -n +N` where N = (number to keep + 1).

## Environment Variables

The pipeline uses the following GoCD environment variables:

- `${GO_PIPELINE_LABEL}` - Automatic build number/label used for image tagging
- `${GO_PIPELINE_NAME}` - Name of the pipeline

## Pipeline Triggers

### Automatic Triggers

By default, the pipeline will trigger on:
- Any commit to the configured Git repository
- Manual trigger via GoCD UI

### Manual Stage Approval

The **Cleanup** stage requires manual approval. To approve:

1. Navigate to the pipeline in GoCD UI
2. Click on the Cleanup stage
3. Click **Approve** (requires `devops` role by default)

## Artifacts

The pipeline generates the following artifacts:

### Build Stage
- `build-artifacts/Dockerfile` - Copy of the Dockerfile used

### Security-Scan Stage
- `security-reports/trivy-report.json` - Machine-readable security scan results
- `security-reports/trivy-report.txt` - Human-readable security scan report

## Troubleshooting

### Build fails with "Docker not found"

Ensure Docker is installed on the GoCD agent and the agent has permissions to run Docker commands:

```bash
# Add GoCD user to docker group
sudo usermod -aG docker go

# Restart GoCD agent
sudo systemctl restart go-agent
```

### Security scan fails

If Trivy installation fails, pre-install it on agents or check network connectivity to GitHub.

### Cleanup stage removes too many images

Adjust the retention policy in the Cleanup stage configuration (see "Modify Cleanup Retention" above).

## Best Practices

1. **Agent Resources**: Tag specific agents with `docker` resource and assign to this pipeline
2. **Notifications**: Configure email/Slack notifications for pipeline failures
3. **Environments**: Create separate GoCD environments (dev, staging, prod) for different deployment targets
4. **Secrets Management**: Use GoCD's secure environment variables for any sensitive data
5. **Regular Updates**: Schedule regular Trivy database updates on agents

## Monitoring

Monitor the pipeline for:
- Build duration (should be 10-15 minutes for full build)
- Security vulnerabilities trending over time
- Image size growth
- Disk space on agents (due to Docker images)

## Support

For issues with:
- **GoCD configuration**: Check GoCD server logs at `/var/log/go-server/`
- **Agent issues**: Check agent logs at `/var/log/go-agent/`
- **Docker builds**: Review build logs in the GoCD UI console output
