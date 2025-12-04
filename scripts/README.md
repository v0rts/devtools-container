# Release Management Scripts

This directory contains scripts for managing releases of the DevTools Container.

## 📝 generate-release-notes.sh

Automatically generates release notes from the release template by extracting version information from the Dockerfile.

### Usage

```bash
./scripts/generate-release-notes.sh <version> [previous-version]
```

### Parameters

- `<version>` (required): The version number for the new release (e.g., 1.0.0)
- `[previous-version]` (optional): The previous version for changelog comparison (e.g., 0.9.0)

### Examples

```bash
# Generate release notes for version 1.0.0
./scripts/generate-release-notes.sh 1.0.0

# Generate with previous version for changelog
./scripts/generate-release-notes.sh 1.1.0 1.0.0
```

### Output

The script will:
1. Extract all tool versions from the Dockerfile
2. Generate a release notes file: `release-notes-v{VERSION}.md`
3. Display next steps for creating the release

### What It Does

- Reads `Dockerfile` to extract all `ARG` version definitions
- Replaces placeholders in `.github/release-template.md`
- Creates a complete release notes document ready for GitHub

## 🚀 Creating a Release

### Option 1: Using GitHub Actions (Recommended)

The easiest way to create a release is through the GitHub Actions workflow:

1. Go to **Actions** → **Create Release** workflow
2. Click **Run workflow**
3. Enter the release version (e.g., `1.0.0`)
4. Optionally enter the previous version for changelog
5. Choose whether to create as draft or pre-release
6. Click **Run workflow**

The workflow will:
- ✅ Validate version format
- ✅ Extract versions from Dockerfile
- ✅ Generate release notes
- ✅ Create Git tag
- ✅ Create GitHub release (draft by default)

### Option 2: Using the Script Manually

For local release creation:

```bash
# Step 1: Generate release notes
./scripts/generate-release-notes.sh 1.0.0 0.9.0

# Step 2: Review and edit the generated file
vi release-notes-v1.0.0.md
# Add your "What's New" items
# Add any "Breaking Changes"

# Step 3: Create the release using gh CLI
gh release create v1.0.0 \
  --title "DevTools Container v1.0.0" \
  --notes-file release-notes-v1.0.0.md \
  --draft

# Step 4: Review the draft at:
# https://github.com/v0rts/devtools-container/releases

# Step 5: Publish when ready (or edit in GitHub UI)
```

### Option 3: Fully Manual

If you prefer the GitHub web interface:

1. Generate release notes: `./scripts/generate-release-notes.sh 1.0.0`
2. Copy contents of `release-notes-v1.0.0.md`
3. Go to GitHub: **Releases** → **Draft a new release**
4. Create tag: `v1.0.0`
5. Paste release notes
6. Edit to add "What's New" section
7. Publish or save as draft

## 📋 Release Checklist

Before creating a release:

- [ ] All CI/CD checks passing on main branch
- [ ] Docker images build successfully
- [ ] Security scans complete without critical issues
- [ ] All documentation is up to date
- [ ] Version numbers in Dockerfile are current
- [ ] CHANGELOG has been updated (if applicable)

After creating the release:

- [ ] Verify release appears on GitHub
- [ ] Check Docker Hub for published images
- [ ] Check GHCR for published images
- [ ] Test pulling and running the tagged image
- [ ] Announce the release (if applicable)

## 🏷️ Version Numbering

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version: Incompatible API changes or breaking changes
- **MINOR** version: New functionality in a backward-compatible manner
- **PATCH** version: Backward-compatible bug fixes

Examples:
- `1.0.0` - Initial stable release
- `1.1.0` - Added new tools or features
- `1.1.1` - Bug fixes or dependency updates
- `2.0.0` - Breaking changes (Ubuntu version upgrade, removed tools, etc.)

## 🔧 Troubleshooting

### Script fails to extract versions

**Problem:** `grep` can't find version ARGs

**Solution:** Ensure Dockerfile has ARG definitions in the format:
```dockerfile
ARG TERRAFORM_LATEST=1.13.0
```

### Release template not found

**Problem:** Script can't find `.github/release-template.md`

**Solution:** Run script from repository root:
```bash
cd /path/to/devtools-container
./scripts/generate-release-notes.sh 1.0.0
```

### GitHub release creation fails

**Problem:** Permission denied or authentication error

**Solution:**
- Ensure you have write access to the repository
- For workflow: Check `contents: write` permission is set
- For gh CLI: Run `gh auth login` first

## 📚 Related Documentation

- **Release Template:** [.github/release-template.md](../.github/release-template.md)
- **Release Workflow:** [.github/workflows/release.yml](../.github/workflows/release.yml)
- **Main README:** [../README.md](../README.md)

## 💡 Tips

1. **Always create draft releases first** to review before publishing
2. **Test the tagged images** before announcing the release
3. **Keep release notes concise** but informative
4. **Use the previous version parameter** for automatic changelog links
5. **Update tool versions in Dockerfile** before creating releases
