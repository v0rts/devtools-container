# Jenkins Pipeline Setup Guide

This guide explains how to set up the Jenkins pipeline for the DevTools Container using Job DSL.

## Pipeline Overview

The Jenkins setup includes:

1. **Main Pipeline** (`devtools-container`) - Builds, scans, tests, and publishes the container
2. **Security Scan Job** (`devtools-container-security-scan`) - Scheduled weekly vulnerability scans
3. **PR Pipeline** (`devtools/devtools-container-pr`) - Automated PR testing
4. **Dashboard View** (`DevTools Pipelines`) - Centralized view of all jobs

## Prerequisites

### Required Jenkins Plugins

Install these plugins via **Manage Jenkins** > **Plugins**:

**Essential:**
- Job DSL Plugin
- Pipeline Plugin
- Docker Pipeline Plugin
- Git Plugin
- Credentials Plugin

**Recommended:**
- AnsiColor Plugin (colored console output)
- Timestamper Plugin (timestamps in logs)
- HTML Publisher Plugin (security reports)
- Email Extension Plugin (notifications)
- GitHub Plugin (webhook integration)

### Jenkins Agent Requirements

Ensure your Jenkins agents have:
- Docker installed and accessible
- Git installed
- Sufficient disk space (20+ GB recommended)
- Network access to Docker registries

**Add Jenkins user to Docker group:**
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

## Setup Instructions

### Step 1: Create Seed Job

The seed job will create all pipeline jobs using Job DSL.

1. Navigate to **New Item**
2. Enter name: `devtools-seed-job`
3. Select **Freestyle project**
4. Click **OK**

### Step 2: Configure Seed Job

**Source Code Management:**
- Select **Git**
- Repository URL: `https://github.com/your-org/devtools-container.git`
- Credentials: Select or add GitHub credentials
- Branch: `*/main`

**Build:**
- Add build step: **Process Job DSLs**
- Select **Look on Filesystem**
- DSL Scripts: `jenkins/devtools-pipeline.groovy`
- Action for removed jobs: **Delete**
- Action for removed views: **Delete**

**Build Triggers:**
- ✓ Poll SCM: `H/5 * * * *` (every 5 minutes)

### Step 3: Create Required Credentials

Navigate to **Manage Jenkins** > **Credentials** > **System** > **Global credentials**

**1. GitHub Credentials** (ID: `github-credentials`)
- Kind: Username with password
- Username: Your GitHub username
- Password: GitHub Personal Access Token
  - Scopes needed: `repo`, `admin:repo_hook`

**2. Docker Registry Credentials** (ID: `docker-registry-credentials`)
- Kind: Username with password
- Username: Docker Hub username
- Password: Docker Hub password or access token

### Step 4: Configure Agent Labels

Tag agents that have Docker installed:

1. **Manage Jenkins** > **Nodes**
2. Select an agent
3. Click **Configure**
4. Add label: `docker`
5. Save

### Step 5: Run Seed Job

1. Navigate to `devtools-seed-job`
2. Click **Build Now**
3. Check console output for success
4. Refresh Jenkins - new jobs should appear

## Pipeline Configuration

### Update Repository URL

Edit `jenkins/devtools-pipeline.groovy`:

```groovy
url('https://github.com/your-org/devtools-container.git')
```

Replace with your actual repository URL.

### Configure Email Notifications

Edit `Jenkinsfile` to update email addresses:

```groovy
to: 'devops-team@example.com'  // Change to your email
```

### Customize Docker Registry

Default is Docker Hub (`docker.io`). To change:

**Option 1:** Update job parameter default in `jenkins/devtools-pipeline.groovy`:
```groovy
stringParam('DOCKER_REGISTRY', 'your-registry.com', 'Docker registry')
```

**Option 2:** Set when triggering build via Jenkins UI

## Job Descriptions

### Main Pipeline (`devtools-container`)

**Stages:**
1. **Preparation** - Clean workspace, checkout code
2. **Build Docker Image** - Build with BuildKit caching
3. **Security Scan** - Trivy vulnerability scanning
4. **Verify Image** - Parallel smoke tests
5. **Generate Reports** - Tool versions, image inspection
6. **Push to Registry** - Push to Docker registry (main/develop only)
7. **Cleanup** - Remove old images

**Parameters:**
- `SKIP_TESTS` - Skip verification (default: false)
- `SKIP_SECURITY_SCAN` - Skip security scan (default: false)
- `PUSH_IMAGE` - Push to registry (default: true)
- `DOCKER_REGISTRY` - Registry URL (default: docker.io)
- `LOG_LEVEL` - Build log level (INFO/DEBUG/WARN)

**Triggers:**
- SCM polling every 5 minutes
- GitHub webhook (if configured)

**Artifacts:**
- `trivy-report.json` - Security scan results (JSON)
- `trivy-report.html` - Security scan results (HTML)
- `tool-versions.txt` - Installed tool versions
- `image-inspect.json` - Docker image metadata

### Security Scan Job (`devtools-container-security-scan`)

**Purpose:** Weekly security scans of the published image

**Schedule:** Sundays at 2 AM

**Notifications:** Emails on failures with vulnerability details

### PR Pipeline (`devtools/devtools-container-pr`)

**Purpose:** Automated testing of pull requests

**Configuration:**
- Scans repository every hour for new PRs
- Builds and tests each PR
- Updates PR status checks
- Trusts contributors only

## Running the Pipeline

### Manual Build

1. Navigate to **devtools-container** job
2. Click **Build with Parameters**
3. Configure options:
   - `SKIP_TESTS`: false
   - `SKIP_SECURITY_SCAN`: false
   - `PUSH_IMAGE`: true
   - `DOCKER_REGISTRY`: docker.io
4. Click **Build**

### Automatic Builds

**Git Push:**
- Push to `main` or `develop` branches
- Jenkins polls every 5 minutes
- Build triggers automatically

**GitHub Webhook (Recommended):**
1. Go to GitHub repository **Settings** > **Webhooks**
2. Add webhook:
   - Payload URL: `http://your-jenkins-url/github-webhook/`
   - Content type: `application/json`
   - Events: Just the push event
3. Save

### Pull Request Testing

1. Create a pull request on GitHub
2. PR pipeline automatically detects and builds
3. Check build status in PR status checks
4. Review build results in Jenkins

## Viewing Results

### Build Status

Navigate to **devtools-container** job to see:
- Build history
- Last success/failure
- Build duration trends

### Security Reports

After each build:
1. Click on a build number
2. Click **Trivy Security Report** in sidebar
3. View interactive HTML report

### Artifacts

Download build artifacts:
1. Navigate to build
2. Scroll to **Build Artifacts**
3. Download files

### Pipeline Stages

View stage execution:
1. Navigate to build
2. Click **Pipeline Steps**
3. Expand stages to see detailed logs

## Email Notifications

Configure Extended Email:

**Manage Jenkins** > **Configure System** > **Extended E-mail Notification**:
- SMTP server: `smtp.gmail.com` (or your server)
- SMTP port: `465`
- Use SSL: ✓
- Credentials: Add SMTP credentials
- Default recipients: `devops-team@example.com`

## GitHub Integration

### Status Checks

Enable GitHub status updates:

1. Install **GitHub Integration Plugin**
2. **Manage Jenkins** > **Configure System**
3. Add GitHub server:
   - API URL: `https://api.github.com`
   - Credentials: GitHub token with `repo:status` scope

### Branch Protection

Configure in GitHub:
1. **Settings** > **Branches**
2. Add rule for `main` branch
3. Require status checks:
   - ✓ `continuous-integration/jenkins/branch`

## Troubleshooting

### "Docker not found" Error

**Solution:**
```bash
# On Jenkins agent
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

Verify: `docker ps` should work as jenkins user

### Job DSL Script Approval

If seed job fails with script approval errors:

1. **Manage Jenkins** > **In-process Script Approval**
2. Approve pending signatures
3. Re-run seed job

### Build Timeout

Increase timeout in `Jenkinsfile`:
```groovy
timeout(time: 120, unit: 'MINUTES')  // Increase to 2 hours
```

### Disk Space Issues

**Solution 1:** Increase cleanup retention:
```groovy
// In Jenkinsfile
buildDiscarder(logRotator(numToKeepStr: '10'))  // Reduce from 30
```

**Solution 2:** Manual cleanup:
```bash
# On Jenkins agent
docker system prune -af
```

### Security Scan Failures

**Install Trivy manually:**
```bash
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | \
    sudo sh -s -- -b /usr/local/bin
```

**Update Trivy database:**
```bash
trivy image --download-db-only
```

## Performance Optimization

### Enable Docker Build Cache

Add to Jenkins agent's Docker daemon (`/etc/docker/daemon.json`):
```json
{
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 10,
  "storage-driver": "overlay2"
}
```

### Use Local Registry Mirror

Speed up pulls by using a registry mirror:
```json
{
  "registry-mirrors": ["http://your-mirror:5000"]
}
```

### Parallel Builds

The Verify stage runs tests in parallel. To add more:

```groovy
parallel {
    stage('Test 1') { ... }
    stage('Test 2') { ... }
    stage('Test 3') { ... }  // Add new test
}
```

## Best Practices

1. **✓ Use dedicated agents** for Docker builds
2. **✓ Monitor disk usage** on agents regularly
3. **✓ Review security scan results** before merging
4. **✓ Keep plugins updated** for security patches
5. **✓ Use credentials** instead of hardcoded secrets
6. **✓ Enable build notifications** for failures
7. **✓ Archive important artifacts** (max 10 builds)
8. **✓ Tag agents** appropriately (docker, linux, etc.)

## Monitoring

### Build Metrics

Track these metrics:
- Build success rate (target: >95%)
- Average build time (should be <15 min)
- Security vulnerability trends
- Disk usage on agents

### Alerts

Set up alerts for:
- Build failures on `main` branch
- Critical security vulnerabilities
- Disk space < 10 GB
- Build time > 30 minutes

## Advanced Configuration

### Multi-Registry Push

Push to multiple registries:

```groovy
stage('Push to Registries') {
    parallel {
        stage('Docker Hub') {
            steps { /* push to docker.io */ }
        }
        stage('Private Registry') {
            steps { /* push to private registry */ }
        }
    }
}
```

### Conditional Stages

Skip stages based on conditions:

```groovy
when {
    anyOf {
        branch 'main'
        branch 'release/*'
    }
}
```

### Shared Libraries

For reusable pipeline code, create a shared library:

1. Create separate Git repo for shared pipeline code
2. **Manage Jenkins** > **Configure System** > **Global Pipeline Libraries**
3. Add library and import in Jenkinsfile:
   ```groovy
   @Library('my-shared-library') _
   ```

## Security Considerations

1. **Credentials Management:**
   - Use Jenkins credentials store
   - Rotate credentials quarterly
   - Use service accounts (not personal)

2. **Access Control:**
   - Enable matrix-based security
   - Limit who can trigger builds
   - Audit permission changes

3. **Network Security:**
   - Use HTTPS for Jenkins
   - Restrict agent network access
   - Use VPN for remote agents

4. **Build Isolation:**
   - Run builds in Docker containers
   - Clean workspace after builds
   - Scan images before deployment

## Support Resources

- **Jenkins Documentation:** https://www.jenkins.io/doc/
- **Job DSL Plugin Wiki:** https://github.com/jenkinsci/job-dsl-plugin/wiki
- **Docker Pipeline Plugin:** https://plugins.jenkins.io/docker-workflow/
- **Trivy Documentation:** https://aquasecurity.github.io/trivy/

## Next Steps

1. ✅ Install required Jenkins plugins
2. ✅ Create and configure seed job
3. ✅ Add credentials (GitHub, Docker Hub)
4. ✅ Run seed job to create pipelines
5. ✅ Configure GitHub webhook
6. ✅ Test build on a branch
7. ✅ Review security scan results
8. ✅ Push successful build to registry
