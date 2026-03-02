A complete **Android TV application** for hospital waiting areas that displays rotating advertisements (images/videos) alongside the CliniqTV queue management system using Picture-in-Picture (PIP) mode.
## Components

### 1. Flutter Android TV App (`/`)
- Full-screen ad display (video + image rotation)
- Picture-in-Picture mode for CliniqTV queue overlay
- D-pad remote control navigation
- Content updates from API (polling)
- Scrolling marquee text banner
- Live clock widget

### 2. Next.js Admin Panel (`/admin-panel`)
- Dashboard with media statistics
- Media upload & management (images, videos)
- Schedule management (time-based ad rotation)
- App settings configuration
- Dark theme UI

### 3. NeonDB Backend (`/supabase_schema.sql`)
- Serverless PostgreSQL database with 4 tables
- Row-Level Security (RLS) policies
- File uploads handled by Next.js API routes
- Media served from admin panel server

---

## Quick Start

### Prerequisites
- Flutter SDK 3.35+
- Node.js 18+
- Android SDK (API 26+)
- NeonDB account (or any PostgreSQL)

### Step 1: Set Up NeonDB

1. Create a database at [neon.tech](https://neon.tech)
2. Go to **SQL Editor** and run the contents of `supabase_schema.sql`
3. Copy your **connection string** from the dashboard

### Step 2: Configure Admin Panel

```bash
cd admin-panel
npm install
```

Edit `.env.local`:
```
DATABASE_URL=postgresql://user:pass@host/neondb?sslmode=require
NEXT_PUBLIC_API_URL=http://localhost:3000
```

### Step 3: Configure Flutter App

Edit `lib/utils/constants.dart`:
```dart
static const String apiBaseUrl = 'http://YOUR_ADMIN_PANEL_IP:3000';
// For emulator use: 'http://10.0.2.2:3000'
// For physical device: 'http://192.168.x.x:3000'
```

### Step 4: Build the APK

```bash
cd ..  # back to root
flutter pub get
flutter build apk --debug
```

APK output: `build/app/outputs/flutter-apk/app-debug.apk`

### Step 5: Run Admin Panel

```bash
cd admin-panel

npm run dev
# Admin panel available at http://localhost:3000

# Run development server
npm run dev

# Build for production
npm run build
npm start
```

---

## Database Schema

### Tables

| Table | Purpose |
|-------|---------|
| `media` | Stores ad content metadata (title, type, URL, order) |
| `schedules` | Time-based schedules for showing specific media |
| `app_settings` | Key-value configuration (rotation interval, marquee text, etc.) |
| `playback_log` | Tracks which ads were displayed and for how long |

### Default Settings

| Key | Default | Description |
|-----|---------|-------------|
| `ad_rotation_interval` | `10` | Seconds between ad transitions |
| `pip_enabled` | `true` | Enable PIP mode |
| `cliniqtv_package` | `com.cliniqtv.app` | CliniqTV Android package |
| `display_mode` | `fullscreen` | Default display mode |
| `marquee_text` | Welcome message | Scrolling bottom text |

---

## TV App Controls (D-pad Remote)

| Button | Action |
|--------|--------|
| **Select/Enter** | Show/hide controls overlay |
| **Left** | Previous ad |
| **Right** | Next ad |
| **Up** | Launch CliniqTV queue app |
| **Down** | Refresh content |
| **Back** | Hide controls / Exit settings |

---

## Project Structure

```
intern/
├── lib/
│   ├── main.dart                  # App entry point
│   ├── models/
│   │   ├── media_item.dart        # Media data model
│   │   ├── schedule.dart          # Schedule data model
│   │   └── app_setting.dart       # Settings data model
│   ├── services/
│   │   ├── supabase_service.dart   # Database & storage operations
│   │   ├── pip_service.dart        # PIP mode (native channel)
│   │   ├── intent_service.dart     # Launch external apps
│   │   └── media_provider.dart     # State management
│   ├── screens/
│   │   ├── home_screen.dart        # Main TV display
│   │   └── settings_screen.dart    # Settings/info screen
│   ├── widgets/
│   │   ├── ad_display_widget.dart  # Video/image ad player
│   │   ├── tv_focus_widgets.dart   # D-pad navigation widgets
│   │   ├── marquee_widget.dart     # Scrolling text banner
│   │   └── clock_widget.dart       # Live clock
│   └── utils/
│       └── constants.dart          # App configuration
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml     # TV & PIP config
│       └── kotlin/.../MainActivity.kt  # Native PIP handler
├── supabase_schema.sql             # Database setup script
├── admin-panel/
│   ├── app/
│   │   ├── page.tsx               # Dashboard
│   │   ├── media/page.tsx         # Media management
│   │   ├── schedules/page.tsx     # Schedule management
│   │   ├── settings/page.tsx      # App settings
│   │   ├── components/
│   │   │   └── Sidebar.tsx        # Navigation sidebar
│   │   └── layout.tsx             # Root layout
│   └── lib/
│       └── supabase.ts            # Supabase client & types
└── README.md                       # This file
```

---

## Key Features

### Real-time Updates
The TV app subscribes to Supabase real-time channels. When you upload new media or change settings in the admin panel, the TV app updates automatically — no restart needed.

### Picture-in-Picture (PIP)
The app uses a native Kotlin MethodChannel to enter Android PIP mode, shrinking the ad display to a corner while CliniqTV runs full-screen for queue management.

### Smart Media Rotation
- Images auto-advance based on the configured interval
- Videos play to completion before advancing
- Display order is manually configurable in the admin panel
- Schedules can restrict media to specific times and days

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| TV App | Flutter 3.35 / Dart 3.9 |
| Admin Panel | Next.js 16 / React 19 / TypeScript |
| Backend | NeonDB (Serverless PostgreSQL) + Next.js API Routes |
| State Management | Provider (ChangeNotifier) |
| Video Playback | video_player package |
| PIP Mode | Custom Kotlin MethodChannel |
| Styling | Tailwind CSS 4 (admin), Material 3 (TV) |

---

## Deployment

### TV App
1. Build release APK: `flutter build apk --release`
2. Install on Android TV device via USB or ADB:
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

### Admin Panel
Deploy to any hosting platform:
- **Vercel**: `npx vercel` (recommended for Next.js)
- **Netlify**: Connect GitHub repo
- **Self-hosted**: `npm run build && npm start`

---

## Team

Built by intern team (5 members) as a hospital queue management solution.
