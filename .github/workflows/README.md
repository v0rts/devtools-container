# GitHub Actions Workflows

This directory contains automated CI/CD workflows for the DevTools Container project.

## Available Workflows

### `build.yml` - Build and Scan DevTools Container

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual trigger via Actions UI

**Jobs:**
1. **build** - Build Docker image with caching
2. **security-scan** - Run Trivy vulnerability scanner
3. **verify** - Test image functionality
4. **publish** - Push to GitHub Container Registry (main only)

**Duration:** ~10-15 minutes (first run), ~5-8 minutes (cached)

## Quick Start

### View Workflow Status

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/devtools-container.git
cd devtools-container

# Push changes to trigger workflow
git add .
git commit -m "Update Dockerfile"
git push origin main
```

Then visit: `https://github.com/YOUR_USERNAME/devtools-container/actions`

### Pull Published Image

```bash
# Authenticate (if private repo)
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Pull latest
docker pull ghcr.io/YOUR_USERNAME/devtools:latest

# Run
docker run -it --rm ghcr.io/YOUR_USERNAME/devtools:latest
```

## Adding a Status Badge

Add to your `README.md`:

```markdown
[![Build Status](https://github.com/YOUR_USERNAME/devtools-container/actions/workflows/build.yml/badge.svg)](https://github.com/YOUR_USERNAME/devtools-container/actions/workflows/build.yml)
```

## Workflow Outputs

Each run produces:
- 📦 Docker image artifact (temporary, 1 day retention)
- 🔒 Security scan reports (SARIF + JSON, 90 days retention)
- 📊 Job summaries with image size and tool versions

## Manual Trigger

1. Go to **Actions** tab
2. Select "Build and Scan DevTools Container"
3. Click **Run workflow**
4. Select branch
5. Click **Run workflow** button

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `IMAGE_NAME` | Docker image name | `devtools` |
| `REGISTRY` | Container registry | `ghcr.io` |

## Permissions Required

The workflow requires these GitHub token permissions:
- `contents: read`
- `packages: write`
- `security-events: write`

These are automatically granted to `GITHUB_TOKEN`.

## Cost

- **Public repos**: FREE (unlimited)
- **Private repos**: Uses your plan's included minutes

Current workflow usage per run:
- ~10-15 minutes for full build
- ~5-8 minutes for cached rebuild

## Troubleshooting

### Build Failing?

Check the workflow logs:
1. **Actions** tab > Click failed run
2. Expand failed job
3. Review error output

Common issues:
- Docker build errors → Check Dockerfile syntax
- Security scan failures → Review vulnerability report
- Test failures → Check tool installation in verify job

### Need Help?

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Report an issue](../../issues)

## Related Documentation

- [Detailed Setup Guide](../../GITHUB-ACTIONS-SETUP.md)
- [GoCD Pipeline](../../GOCD-SETUP.md)
- [Main README](../../README.md)
