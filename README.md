# LeetCode War Room 🎯

A Flutter web application for tracking and visualizing LeetCode progress with leaderboard, analytics, and progress tracking features.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Active Supabase project

### Setup & Running

1. **Clone and install dependencies**
   ```bash
   git clone https://github.com/User719-blip/leetcode_tracker_web.git
   cd leetcode_tracker_web
   flutter pub get
   ```

2. **Run locally**
   
   The repo includes `.vscode/launch.json` with your credentials configured.
   
   **Using VS Code:** Press F5 or select "leetcode_tracker_web (chrome)" from Run menu
   
   **Using Command Line:**
   ```bash
   flutter run -d chrome \
     --dart-define=SUPABASE_URL=https://sukxolpjeagqybohmjdk.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=your-anon-key
   ```

## 📦 Deployment to GitHub Pages

### One-Time Setup

1. **Add GitHub Secrets** (Settings → Secrets and variables → Actions)
   - `SUPABASE_URL`: `https://sukxolpjeagqybohmjdk.supabase.co`
   - `SUPABASE_ANON_KEY`: Your Supabase anon key

2. **Enable GitHub Pages** (Settings → Pages)
   - Source: Select "GitHub Actions"

### Auto-Deploy

Every push to `main` branch automatically deploys to:
**https://User719-blip.github.io/leetcode_tracker_web/**

```bash
git add .
git commit -m "Update"
git push origin main
```

GitHub Actions workflow (`.github/workflows/deploy.yml`) handles the rest!

## 🏗️ Manual Production Build

```bash
flutter build web \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=APP_ENV=prod \
  --release
```

## 📚 Key Files

- [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) - Automated GitHub Pages deployment
- [`.vscode/launch.json`](.vscode/launch.json) - VS Code run configurations
- [`BUILD.md`](BUILD.md) - Detailed build/deployment guide
- [`lib/config/env_config.dart`](lib/config/env_config.dart) - Environment configuration

## 🔒 Security

✅ **Safe to commit:** `.vscode/launch.json` with Supabase anon keys (they're public by design)  
✅ **Protected:** All database operations secured by Supabase Row Level Security (RLS)  
❌ **Never commit:** Service role keys or passwords  
✅ **GitHub Secrets:** Used in CI/CD for production deployments

## 📸 Features

- 🏆 Real-time leaderboard with rankings and animations
- 📊 Analytics dashboard with global trends & insights
- 📈 7-day sparkline progress charts
- 🎯 Difficulty distribution visualization
- 🏅 Achievement badges (Weekly/Monthly)
- 🥇 Podium display for top 3 with confetti
- 📱 Fully responsive (iPhone, Android, Desktop)

## 🛠️ Tech Stack

- **Framework:** Flutter Web (Material Design 3)
- **Backend:** Supabase (PostgreSQL + Edge Functions)
- **Hosting:** GitHub Pages (Static)
- **CI/CD:** GitHub Actions
- **Charts:** Custom Canvas painters + FL Chart

## 🆘 Troubleshooting

**"SUPABASE_URL is not set" error:**
Pass `--dart-define` flags or check `.vscode/launch.json`

**GitHub Actions fails:**
Verify repository secrets are set correctly in Settings → Secrets

**Local dev issues:**
```bash
flutter clean && flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

---

For detailed instructions, see [`BUILD.md`](BUILD.md)

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
