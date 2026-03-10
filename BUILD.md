# Build & Deployment Guide

## Environment Configuration

This project uses **compile-time environment variables** for configuration, which works perfectly with static hosting platforms like GitHub Pages.

### Development

For local development, you have two options:

#### Option 1: Command-line flags (Recommended)
```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

#### Option 2: VS Code Launch Configuration
Create `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "leetcode_tracker_web (dev)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=SUPABASE_URL=https://your-project.supabase.co",
        "--dart-define=SUPABASE_ANON_KEY=your-anon-key",
        "--dart-define=APP_ENV=dev"
      ]
    }
  ]
}
```

### Production Build for GitHub Pages

```bash
flutter build web \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=APP_ENV=prod \
  --release
```

### GitHub Actions CI/CD

Add your Supabase credentials as **GitHub Secrets**:
1. Go to your repository → Settings → Secrets and variables → Actions
2. Add secrets:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
      
      - name: Build Flutter Web
        run: |
          flutter pub get
          flutter build web \
            --dart-define=SUPABASE_URL=${{ secrets.SUPABASE_URL }} \
            --dart-define=SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }} \
            --dart-define=APP_ENV=prod \
            --release \
            --base-href /${{ github.event.repository.name }}/
      
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
```

## Security Notes

- ✅ **Safe**: Supabase ANON keys are designed to be public (they're used in frontend apps)
- ✅ **Safe**: These keys are protected by Row Level Security (RLS) policies in Supabase
- ❌ **Never commit**: Service role keys or other sensitive credentials
- ✅ **Always use**: GitHub Secrets for CI/CD pipelines

## Troubleshooting

### "SUPABASE_URL is not set" error
You forgot to pass the `--dart-define` flags. Use one of the commands above.

### VS Code not using environment variables
Make sure your `.vscode/launch.json` is configured with the dart-define args.

### GitHub Pages deployment fails
1. Check that secrets are properly set in repository settings
2. Verify the workflow file syntax
3. Check GitHub Actions logs for specific error messages
