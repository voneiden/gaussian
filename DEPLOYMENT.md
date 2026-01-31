# Deployment Guide

## Quick Reference

### Automatic Deployment (Recommended)

Simply push to the `main` branch:

```bash
git add .
git commit -m "Your changes"
git push origin main
```

The GitHub Actions workflow will automatically:
1. ✓ Check out the code
2. ✓ Set up Gleam and Erlang
3. ✓ Download dependencies
4. ✓ Build minified production bundle
5. ✓ Deploy to GitHub Pages

Your changes will be live at `https://<username>.github.io/gaussian/` in 1-2 minutes.

### Manual Build

For local testing before deployment:

```bash
# Build production bundle
gleam run -m lustre/dev build --minify --outdir=dist

# Test locally
cd dist && python3 -m http.server 8000
# Visit http://localhost:8000
```

### Build Options

```bash
# Production build (minified)
gleam run -m lustre/dev build --minify

# Development build (readable)
gleam run -m lustre/dev build

# Custom output directory
gleam run -m lustre/dev build --outdir=docs

# Skip HTML generation
gleam run -m lustre/dev build --no-html

# Skip Tailwind processing
gleam run -m lustre/dev build --no-tailwind
```

## Troubleshooting

### Build Fails in GitHub Actions

1. Check the workflow run in the "Actions" tab
2. Verify `gleam.toml` dependencies are correct
3. Ensure tests pass locally: `gleam test`
4. Check for warnings: `gleam check`

### GitHub Pages Not Working

1. Go to Settings → Pages
2. Verify Source is set to "GitHub Actions"
3. Check the latest workflow run completed successfully
4. Wait 1-2 minutes for DNS propagation

### CSS Not Loading

If styles don't appear:
1. Check `src/gaussian.css` exists
2. Verify Tailwind is configured in `gleam.toml`
3. Check browser console for 404 errors
4. Ensure paths in HTML are correct (should be relative)

## Workflow Configuration

The deployment workflow is defined in `.github/workflows/deploy.yml`:

- **Trigger**: Push to `main` branch or manual dispatch
- **Erlang**: v27.0
- **Gleam**: v1.6.1
- **Build**: Minified, outputs to `dist/`
- **Deploy**: GitHub Pages (requires Pages enabled in settings)

## First-Time Setup Checklist

- [ ] Repository created on GitHub
- [ ] Code pushed to `main` branch
- [ ] GitHub Pages enabled (Settings → Pages → Source: GitHub Actions)
- [ ] Workflow file exists: `.github/workflows/deploy.yml`
- [ ] First push triggers workflow run
- [ ] Site accessible at `https://<username>.github.io/gaussian/`

## Version History

To see deployment history:
1. Go to the "Actions" tab in GitHub
2. Click on "Deploy to GitHub Pages"
3. View all past workflow runs with status and logs
