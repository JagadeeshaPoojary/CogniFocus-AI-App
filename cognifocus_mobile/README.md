# CogniFocus-AI Mobile (Flutter + Claymorphism UI)

CogniFocus-AI Mobile is a production-grade Flutter application migrated from React Native/Expo. It introduces a tactile **Claymorphism** design system, replaces fragile glass panels with soft pastel raised 3D surfaces, and interfaces with the Flask/Python multi-camera AI monitoring engine.

---

## 📱 Key Features & Architecture

- **Tactile Claymorphism UI**:
  - Soft pastel backgrounds and dual-shadowed 3D raised surfaces (`ClayCard`, `ClayButton`, `ClayInput`, `ClayStatCard`, `ClayStatusBadge`).
  - Tactile micro-interactions (press depression and subtle elevation changes).
  - Coordinated palette: Soft Lavender (`#EDEEF9`), Pale Blue (`#E8F1FC`), Mint Green (`#EBF7F0`), Warm Amber (`#FEF6E9`), Dark Slate typography (`#1E293B`), and Soft Coral (`#EF4444`) for critical alerts.
- **Centralized Networking & Role Routing**:
  - Clean separation of Admin and Teacher dashboards.
  - Token-based JWT authentication (`POST /api/auth/login`, `GET /api/auth/me`).
  - Dual error handling: distinguishes temporary network errors from expired sessions (401).
- **Teacher Workspace**:
  - Classroom access code validation (`CSE301` / `CSE302`).
  - Start & Stop monitoring leases (`POST /api/teacher/classroom/enter`, `POST /api/teacher/classroom/leave`).
  - Assigned classroom isolation and real-time statistics (`GET /api/teacher/dashboard/stats`).
- **Admin System Dashboard**:
  - Multi-camera worker lease control (`POST /api/admin/start-monitoring`, `POST /api/admin/stop-monitoring`).
  - System metrics (Total Students, Active Cameras, Active Alerts, Alerts Today).
- **Live AI Camera Monitoring**:
  - Fetches processed frames directly from Flask OpenCV workers via `GET /api/cameras/<id>/frame.jpg`.
  - Single and multi-grid view modes with pause/resume and auto-reconnect.
  - Zero heavy local inference: OpenCV and YOLOv8 workers execute exclusively on the host server.
- **Incident Alerts & Evidence Review**:
  - Filterable by Status (`Active`, `Acknowledged`, `Resolved`) and Timeframe (`Today`, `Yesterday`, `7 Days`).
  - Student evidence preview dialog (`EvidenceModal`) with zoomable snapshot, student ID, seat label, and duration.
  - Acknowledge and Resolve actions with immediate backend sync.
- **Local Notifications**:
  - Native alert channels powered by `flutter_local_notifications` with Android 13+ permission handling.
- **Configurable Endpoints & Diagnostics**:
  - Dynamic host IP switching for Android Emulator (`http://10.0.2.2:5000`) and physical devices (`http://192.168.x.x:5000`).
  - Built-in live connection diagnostic test.

---

## 📂 Project Directory Structure

```text
cognifocus_mobile/
├── android/
│   └── app/src/main/AndroidManifest.xml    # Cleartext traffic & network permissions
├── lib/
│   ├── main.dart                           # Flutter initialization & entry point
│   ├── app.dart                            # MultiProvider setup & theme root
│   ├── core/
│   │   ├── config/
│   │   │   └── api_config.dart             # Centralized API endpoints & builders
│   │   ├── network/
│   │   │   └── api_client.dart             # HTTP client, Bearer auth, timeouts & diagnostics
│   │   └── theme/
│   │       ├── app_theme.dart              # Material 3 theme configuration
│   │       ├── clay_colors.dart            # Coordinated pastel clay palette
│   │       └── clay_styles.dart            # 3D raised, pressed, and inset box decorations
│   ├── models/
│   │   ├── alert_model.dart                # Incident alert model
│   │   ├── camera_model.dart               # Camera worker model
│   │   ├── classroom_model.dart            # Classroom hall model
│   │   ├── stats_model.dart                # Admin & Teacher metrics models
│   │   └── user_model.dart                 # User profile & role model
│   ├── navigation/
│   │   └── app_router.dart                 # Role-based router & bottom tab host
│   ├── providers/
│   │   ├── admin_provider.dart             # Admin metrics & camera leases
│   │   ├── alerts_provider.dart            # Alert filtering & actions
│   │   ├── auth_provider.dart              # Auth session, roles, & classroom state
│   │   └── teacher_provider.dart           # Teacher workspace & stats
│   ├── screens/
│   │   ├── admin/
│   │   │   └── admin_dashboard_screen.dart # Admin metrics & global camera control
│   │   ├── alerts/
│   │   │   └── alerts_screen.dart          # Alert feed, filters, & evidence modal
│   │   ├── auth/
│   │   │   └── login_screen.dart           # Auth, branding, demo pills, & server config
│   │   ├── classrooms/
│   │   │   └── classrooms_screen.dart      # Classroom directory & monitoring launch
│   │   ├── monitoring/
│   │   │   └── live_monitoring_screen.dart # Multi-camera live stream viewer
│   │   ├── settings/
│   │   │   └── settings_screen.dart        # Server diagnostics, profile, & notifications
│   │   └── teacher/
│   │       └── teacher_dashboard_screen.dart # Code entry, start/stop, & session stats
│   ├── services/
│   │   ├── alerts_service.dart             # Alerts API service
│   │   ├── auth_service.dart               # Login, getMe, & logout service
│   │   ├── monitor_service.dart            # Admin monitoring service
│   │   ├── notification_service.dart       # Local notifications & preferences
│   │   ├── storage_service.dart            # SharedPreferences token & URL persistence
│   │   └── teacher_service.dart            # Teacher classroom & stats service
│   └── widgets/
│       ├── app_header.dart                 # Tactile app header with refresh
│       ├── camera_player.dart              # Live camera player with byte caching
│       ├── clay_button.dart                # 3D tactile button with press feedback
│       ├── clay_card.dart                  # Raised clay surface with dual shadows
│       ├── clay_input.dart                 # Inset rounded input field
│       ├── clay_navigation_bar.dart        # Tactile bottom navigation bar
│       ├── clay_stat_card.dart             # Dashboard metric card
│       ├── clay_status_badge.dart          # Pill status indicators (Live/Active/High)
│       └── evidence_modal.dart             # Student evidence snapshot viewer
├── test/
│   ├── models_and_config_test.dart         # Unit tests for models & ApiConfig (10 tests)
│   ├── network_and_auth_test.dart          # Unit tests for API client & services (6 tests)
│   └── widget_test.dart                    # Widget tests for Clay UI & LoginScreen (8 tests)
└── pubspec.yaml                            # Dependencies & assets configuration
```

---

## 📦 Packages Added

| Package | Version | Purpose |
|---|---|---|
| `http` | `^1.6.0` | Standard HTTP client for API and JPEG frame streaming |
| `provider` | `^6.1.5` | Reactive state management for Auth, Teacher, Admin, and Alerts |
| `shared_preferences` | `^2.5.6` | Persistent storage for JWT tokens, user profiles, and server URL |
| `flutter_local_notifications` | `^22.3.1` | Native local incident notification alerts and sound channels |
| `intl` | `^0.20.3` | Date and timestamp formatting |

---

## 🚀 Exact Windows Commands to Run the App

### 1. Ensure Dependencies are Installed
```powershell
cd "c:\CogniFocus- AI  App\cognifocus_mobile"
flutter pub get
```

### 2. Run All Tests
```powershell
flutter test
```

### 3. Run Static Analysis & Formatting
```powershell
flutter analyze
dart format .
```

### 4. Run on Connected Device / Emulator
```powershell
# Check available devices (Android emulator, physical phone, Windows desktop)
flutter devices

# Run on the default active device
flutter run

# Run specifically on Android
flutter run -d android
```

---

## 🌐 Configuring Laptop Backend IP Address

### 1. Finding Your Laptop IPv4 Address
In Windows PowerShell or Command Prompt, run:
```powershell
ipconfig
```
Look for `IPv4 Address` under your active Wi-Fi adapter (e.g. `192.168.1.5`).

### 2. Windows Firewall Setup
Allow inbound traffic on port 5000 so the mobile phone on your Wi-Fi network can reach the Flask server:
```powershell
netsh advfirewall firewall add rule name="CogniFocus Flask Server" dir=in action=allow protocol=TCP localport=5000
```

### 3. Server Configuration in the App
You can configure the server URL in two easy ways:
1. **On the Login Screen**: Tap the server indicator pill at the bottom (`Server: http://...`) to open the **Server Configuration Dialog**, enter your URL, and tap **Test Connection**.
2. **In App Settings**: Navigate to **Settings** -> **Backend Endpoint Settings**, update the URL, and tap **Save Endpoint**.

- **Android Emulator**: `http://10.0.2.2:5000`
- **Physical Android Phone**: `http://<laptop_ip>:5000` (e.g., `http://192.168.1.5:5000`)
- **Production Server**: `https://your-domain.com`

---

## 📱 Android Phone Testing Instructions

1. Connect your Android phone and laptop to the **same Wi-Fi network**.
2. Enable **Developer Options** and **USB Debugging** on your phone.
3. Plug in the USB cable and verify connection:
   ```powershell
   flutter devices
   ```
4. Build and run the app:
   ```powershell
   flutter run -d <your-device-id>
   ```
5. On the Login screen, open the Server Configuration dialog and set the URL to `http://<laptop_ip>:5000`. Tap **Test Connection** to confirm connectivity.
6. Use demo credentials to sign in:
   - **Teacher**: `teacher@classroom.com` / `teacher123`
   - **Admin**: `admin@classroom.com` / `admin123`

---

## 🧪 Automated Test Results

All 24 automated unit and widget tests pass:

```text
✓ ApiConfig Tests normalizeUrl handles trailing slashes, spaces, and missing protocol
✓ ApiConfig Tests getCameraFrameUrl constructs valid frame url with token and timestamp
✓ ApiConfig Tests getEvidenceUrl builds absolute and relative URL correctly
✓ UserModel Tests parses Admin user from JSON and normalizes role
✓ UserModel Tests parses Teacher user from JSON
✓ ClassroomModel Tests parses classroom with default counts
✓ CameraModel Tests correctly identifies online status
✓ AlertModel Tests parses AlertModel and formats duration
✓ StatsModel Tests parses AdminStatsModel correctly
✓ StatsModel Tests parses TeacherStatsModel correctly
✓ StorageService Tests saves and retrieves token, user, and server url
✓ AuthService Tests successful login parses token and user
✓ AuthService Tests failed login throws ApiException with server error message
✓ TeacherService Tests enterClassroom parses cameras and session state
✓ TeacherService Tests leaveClassroom stops monitoring successfully
✓ AlertsService Tests acknowledge and resolve send proper requests
✓ Claymorphism Reusable Widgets Tests ClayCard renders child with 3D raised decoration
✓ Claymorphism Reusable Widgets Tests ClayButton renders text and triggers callback
✓ Claymorphism Reusable Widgets Tests ClayButton shows loading spinner when isLoading is true
✓ Claymorphism Reusable Widgets Tests ClayInput renders with label, hint, and icons
✓ Claymorphism Reusable Widgets Tests ClayStatusBadge renders live, offline, and severity badges
✓ Claymorphism Reusable Widgets Tests ClayStatCard renders metric title, value, and subtitle
✓ Claymorphism Reusable Widgets Tests ClayNavigationBar renders tabs with active pill
✓ LoginScreen Widget Tests LoginScreen renders CogniFocus branding, fields, and quick demo pills

All 24 tests passed!
```
