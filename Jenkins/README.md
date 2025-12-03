# Jenkins Pipeline Configuration

This directory contains Jenkins pipeline configuration using Job DSL.

## Files

- **`devtools-pipeline.groovy`** - Job DSL script that creates all pipeline jobs
- **`../Jenkinsfile`** - Declarative pipeline script referenced by jobs

## Quick Start

### 1. Create Seed Job

In Jenkins UI:
1. **New Item** → Name: `devtools-seed-job` → **Freestyle project**
2. **Source Code Management** → Git:
   - URL: `https://github.com/your-org/devtools-container.git`
   - Credentials: Add GitHub credentials
3. **Build** → Add build step: **Process Job DSLs**
   - Look on Filesystem
   - DSL Scripts: `jenkins/devtools-pipeline.groovy`
4. **Build Triggers** → Poll SCM: `H/5 * * * *`
5. **Save**

### 2. Configure Credentials

**Manage Jenkins** > **Credentials** > Add:

| ID | Type | Usage |
|----|------|-------|
| `github-credentials` | Username/Password | GitHub access |
| `docker-registry-credentials` | Username/Password | Docker Hub push |

### 3. Run Seed Job

1. Click **Build Now** on `devtools-seed-job`
2. Wait for completion
3. Refresh Jenkins

**Created jobs:**
- `devtools-container` - Main build pipeline
- `devtools-container-security-scan` - Weekly security scans
- `devtools/devtools-container-pr` - PR testing
- `DevTools Pipelines` view

## Pipeline Jobs

### Main Pipeline: `devtools-container`

**Stages:**
1. Preparation
2. Build Docker Image
3. Security Scan (Trivy)
4. Verify Image (parallel tests)
5. Generate Reports
6. Push to Registry (main/develop only)
7. Cleanup

**Duration:** 10-15 minutes

**Triggers:**
- Git push (via polling or webhook)
- Manual build with parameters

**Parameters:**
- `SKIP_TESTS` - Skip verification tests
- `SKIP_SECURITY_SCAN` - Skip Trivy scan
- `PUSH_IMAGE` - Push to registry
- `DOCKER_REGISTRY` - Registry URL
- `LOG_LEVEL` - Build verbosity

### Security Scan: `devtools-container-security-scan`

**Schedule:** Sundays at 2 AM

**Purpose:** Weekly vulnerability scans of published images

**Notifications:** Email on critical findings

### PR Testing: `devtools/devtools-container-pr`

**Triggers:** New pull requests (hourly scan)

**Purpose:** Automated PR validation

## Customization

### Change Repository URL

Edit `devtools-pipeline.groovy` line 25:
```groovy
url('https://github.com/YOUR-ORG/devtools-container.git')
```

### Modify Build Parameters

Edit `devtools-pipeline.groovy` parameters section:
```groovy
parameters {
    booleanParam('SKIP_TESTS', false, 'Skip verification')
    stringParam('NEW_PARAM', 'value', 'Description')
}
```

### Add Build Stages

Edit `../Jenkinsfile`:
```groovy
stage('New Stage') {
    steps {
        // Your build steps
    }
}
```

### Change Email Recipients

Edit `../Jenkinsfile` post sections:
```groovy
to: 'your-team@example.com'
```

## Job DSL Features

The Job DSL script creates:

**✓ Pipeline job** with Git SCM and triggers
**✓ Security scan job** with cron schedule
**✓ Multibranch pipeline** for PR testing
**✓ Dashboard view** for all jobs
**✓ Log rotation** for artifact management
**✓ Build wrappers** (timestamps, ANSI colors)

## Required Plugins

Install via **Manage Jenkins** > **Plugins**:

**Essential:**
- Job DSL Plugin
- Pipeline Plugin
- Docker Pipeline Plugin
- Git Plugin

**Recommended:**
- AnsiColor Plugin
- Timestamper Plugin
- HTML Publisher Plugin
- Email Extension Plugin

## Agent Requirements

Tag agents with label: `docker`

**Required on agents:**
- Docker (accessible to Jenkins user)
- Git
- 20+ GB disk space

**Setup:**
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

## Viewing Results

### Build Status
Navigate to job → Build History

### Security Reports
Build → **Trivy Security Report** (HTML)

### Artifacts
Build → **Build Artifacts** → Download

### Console Output
Build → **Console Output**

## Troubleshooting

**Issue:** Job DSL script approval errors
**Fix:** Manage Jenkins → In-process Script Approval → Approve

**Issue:** Docker permission denied
**Fix:** Add Jenkins user to docker group (see Agent Requirements)

**Issue:** Trivy not found
**Fix:** Install on agents: `curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin`

## Webhook Setup (Optional)

For instant builds on push:

**GitHub:**
1. Repository → Settings → Webhooks
2. Add webhook:
   - URL: `http://jenkins-url/github-webhook/`
   - Content type: application/json
   - Events: push
3. Save

**Jenkins will trigger on:**
- Pushes to main/develop
- New pull requests

## Best Practices

1. ✅ Keep seed job updated with latest DSL
2. ✅ Review security scan results before merging
3. ✅ Monitor agent disk usage
4. ✅ Rotate credentials quarterly
5. ✅ Archive artifacts (limit to 10 builds)
6. ✅ Use parameters instead of hardcoded values
7. ✅ Test changes on feature branches first

## Documentation

- [Detailed Setup Guide](../JENKINS-SETUP.md)
- [Jenkinsfile Reference](../Jenkinsfile)
- [Job DSL API](https://jenkinsci.github.io/job-dsl-plugin/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)

## Support

For issues:
1. Check build console output
2. Review [JENKINS-SETUP.md](../JENKINS-SETUP.md)
3. Verify agent configuration
4. Check Jenkins system logs
