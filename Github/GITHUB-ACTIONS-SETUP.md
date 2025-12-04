# GitHub Actions Pipeline Setup Guide

This guide explains the GitHub Actions workflow for building, scanning, and publishing the DevTools Container.

## Pipeline Overview

The workflow consists of 4 jobs that run in sequence:

1. **Build** - Builds the Docker image with caching
2. **Security-Scan** - Scans for vulnerabilities using Trivy
3. **Verify** - Runs comprehensive smoke tests
4. **Publish** - Pushes to GitHub Container Registry (main branch only)

## Workflow Triggers

The pipeline runs on:
- **Push** to `main` or `develop` branches (excluding `.md` files)
- **Pull requests** to `main` or `develop` branches
- **Manual trigger** via GitHub Actions UI

## Prerequisites

### Repository Settings

1. **Enable GitHub Actions**:
   - Go to **Settings** > **Actions** > **General**
   - Ensure "Allow all actions and reusable workflows" is selected

2. **Enable GitHub Container Registry**:
   - No additional setup needed - GHCR is enabled by default
   - Images will be published to `ghcr.io/YOUR_USERNAME/devtools`

3. **Set Package Visibility** (Optional):
   - After first publish, go to **Packages** on your GitHub profile
   - Find the `devtools` package
   - Click **Package settings** > Change visibility to Public or Private

### Required Permissions

The workflow uses `GITHUB_TOKEN` with these permissions:
- `contents: read` - Read repository code
- `packages: write` - Push to GitHub Container Registry

These are automatically provided by GitHub Actions.

## Features

### 🏗️ Build Stage
- Uses Docker Buildx for efficient builds
- Implements GitHub Actions cache for faster rebuilds
- Tags with multiple formats:
  - Branch name (e.g., `main`, `develop`)
  - Git SHA (e.g., `main-abc1234`)
  - `latest` (for main branch only)

### 🔒 Security Scan Stage
- Scans for CRITICAL, HIGH, and MEDIUM vulnerabilities
- Generates JSON report with detailed findings
- Shows summary table in workflow output
- Stores report as artifact (downloadable for 90 days)

### ✅ Verify Stage
- Tests container starts successfully
- Verifies all tools are installed:
  - asdf, Terraform, Python, Node.js, kubectl, Helm, Rust, Go
  - Python packages: Ansible, AWS CLI
- Reports image size in job summary
- Lists all installed tool versions

### 📦 Publish Stage
- **Only runs on `main` branch** (not PRs)
- Requires all previous jobs to pass
- Pushes to GitHub Container Registry
- Provides pull and run commands in summary

## Viewing Results

### Build Status Badge

Add this to your `README.md`:

```markdown
![Build Status](https://github.com/YOUR_USERNAME/devtools-container/actions/workflows/build.yml/badge.svg)
```

Replace `YOUR_USERNAME` with your GitHub username.

### Security Scan Results

View scan results in workflow logs:
1. Go to **Actions** tab
2. Click on a workflow run
3. Open the **security-scan** job
4. View the Trivy table output in logs

Download detailed reports from artifacts (see below).

### Job Summaries

Each workflow run generates a detailed summary:
- Navigate to **Actions** tab
- Click on a workflow run
- Scroll down to see:
  - Image size report
  - Installed tool versions
  - Deployment commands (for published images)

### Download Artifacts

Security reports are saved as artifacts:
1. Go to **Actions** > Select a workflow run
2. Scroll to **Artifacts** section
3. Download `trivy-security-report`

## Usage Examples

### Pull the Image

After the workflow publishes to GHCR:

```bash
# Authenticate with GHCR (one-time setup)
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Pull the latest image
docker pull ghcr.io/YOUR_USERNAME/devtools:latest

# Run the container
docker run -it --rm -v $(pwd):/home/tooluser/workspace ghcr.io/YOUR_USERNAME/devtools:latest
```

### Trigger Manual Build

1. Go to **Actions** tab
2. Select "Build and Scan DevTools Container" workflow
3. Click **Run workflow**
4. Choose branch and click **Run workflow**

## Customization

### Change Security Scan Severity

Edit `.github/workflows/build.yml`:

```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    severity: 'CRITICAL,HIGH'  # Add MEDIUM, LOW as needed
```

### Add Additional Tests

Add new steps to the `verify` job:

```yaml
- name: Test custom functionality
  run: |
    docker run --rm ${{ env.REGISTRY }}/${{ github.repository_owner }}/${{ env.IMAGE_NAME }}:${{ github.ref_name }}-${{ github.sha }} \
      bash -c 'YOUR_COMMAND_HERE'
```

### Publish to Docker Hub Instead

Replace GHCR login with Docker Hub:

```yaml
- name: Log in to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
```

Then add secrets in **Settings** > **Secrets and variables** > **Actions**.

### Enable Branch Protection

Require workflow to pass before merging:

1. Go to **Settings** > **Branches**
2. Add branch protection rule for `main`
3. Enable "Require status checks to pass"
4. Select workflow jobs: `build`, `security-scan`, `verify`

## Caching Strategy

The workflow uses GitHub Actions cache for Docker layers:

```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

This significantly speeds up rebuilds by reusing unchanged layers.

**Cache limits:**
- 10 GB per repository
- Automatically evicts old cache entries

## Cost Optimization

### For Public Repositories
- ✅ **FREE** - Unlimited minutes
- ✅ **FREE** - Unlimited storage for public packages

### For Private Repositories
- 2,000 minutes/month on free plan
- Storage: 500 MB free, then $0.008/GB/day

**Tips to reduce usage:**
- Use `paths-ignore` to skip builds for doc changes
- Cache Docker layers effectively
- Clean up old packages regularly

## Troubleshooting

### Build Fails: "Permission denied"

Ensure your repository has Actions enabled:
- **Settings** > **Actions** > **General** > Enable Actions

### Security Scan Shows No Results

This is normal if no vulnerabilities are found. Check the job logs for confirmation.

### Publish Fails: "unauthorized"

Ensure the workflow has `packages: write` permission. This is configured in the workflow YAML.

### Image Too Large

Monitor image size in the verify job summary. Consider:
- Using multi-stage builds
- Cleaning up cache after package installs
- Removing unnecessary dependencies

## Monitoring

### Set Up Notifications

1. **Email**: Automatically sent for failed workflows
2. **Slack**: Use GitHub's Slack integration
3. **Custom webhooks**: Add workflow dispatch events

### Track Metrics

Monitor in **Actions** > **Workflows**:
- Success/failure rate
- Build duration (should be 10-15 min for full build)
- Cache hit rate

## Security Best Practices

1. ✅ Never commit secrets to the repository
2. ✅ Use GitHub Secrets for sensitive data
3. ✅ Review Trivy results before merging
4. ✅ Enable Dependabot for workflow dependencies
5. ✅ Use pinned action versions (e.g., `@v4`, not `@main`)

## Advanced Features

### Matrix Builds

To build multiple versions, add a matrix strategy:

```yaml
strategy:
  matrix:
    version: [ubuntu-22.04, ubuntu-24.04]
runs-on: ${{ matrix.version }}
```

### Scheduled Scans

Add a schedule trigger for regular security scans:

```yaml
on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
```

### Deploy to Multiple Registries

Add steps to push to both GHCR and Docker Hub in the publish job.

## Support

- **GitHub Actions Docs**: https://docs.github.com/actions
- **Trivy Documentation**: https://aquasecurity.github.io/trivy/
- **Docker Buildx**: https://docs.docker.com/buildx/

## Next Steps

1. Push this repository to GitHub
2. Verify the workflow runs automatically
3. Check the **Actions** tab for results
4. Review security scan results in workflow logs
5. Download and review the security report artifact
6. Pull and test the published image from GHCR
