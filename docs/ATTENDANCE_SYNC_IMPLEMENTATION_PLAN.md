# EduX Teacher Mobile Attendance - Implementation Plan

## Executive Summary

This document outlines the implementation of a distributed attendance system allowing teachers to mark attendance on Android devices throughout the day, then sync with the main office system over local WiFi at the end of the day.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    MAIN SYSTEM (Hub/Server)                      │
│                   (Office Computer - Desktop)                    │
│  ┌──────────────────────┐    ┌──────────────────────────────┐  │
│  │   SQLite Master DB   │    │     HTTP Sync Server         │  │
│  │  (Drift/SQLite)      │◄──►│  • mDNS Service Discovery    │  │
│  │                      │    │  • Teacher Authentication    │  │
│  │  Tables:             │    │  • Class/Student Data API    │  │
│  │  - Students          │    │  • Attendance Sync API       │  │
│  │  - Attendance        │    │  • Device Management         │  │
│  │  - Staff/Assignments │    │                              │  │
│  │  - Users             │    │  Port: 8181 (configurable)   │  │
│  └──────────────────────┘    └──────────────────────────────┘  │
│                              ┌──────────────────────────────┐  │
│                              │  Device Management UI        │  │
│                              │  (Settings > Sync Devices)   │  │
│                              └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │ Local WiFi/LAN (Same Network)
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│  Teacher App    │   │  Teacher App    │   │  Teacher App    │
│  (Android)      │   │  (Android)      │   │  (Android)      │
│                 │   │                 │   │                 │
│ ┌─────────────┐ │   │ ┌─────────────┐ │   │ ┌─────────────┐ │
│ │ SQLite      │ │   │ │ SQLite      │ │   │ │ SQLite      │ │
│ │ Cache DB    │ │   │ │ Cache DB    │ │   │ │ Cache DB    │ │
│ │ (Drift)     │ │   │ │ (Drift)     │ │   │ │ (Drift)     │ │
│ └─────────────┘ │   │ └─────────────┘ │   │ └─────────────┘ │
│                 │   │                 │   │                 │
│ • Auto-discover │   │ • Auto-discover │   │ • Auto-discover │
│ • Offline cache │   │ • Offline cache │   │ • Offline cache │
│ • Quick mark    │   │ • Quick mark    │   │ • Quick mark    │
│ • End-of-day    │   │ • End-of-day    │   │ • End-of-day    │
│   sync          │   │   sync          │   │   sync          │
└─────────────────┘   └─────────────────┘   └─────────────────┘
```

## Data Flow

### 1. Initial Setup (One-time per teacher)
1. Admin creates Staff record with linked User account
2. Admin assigns teacher to classes/subjects in main system
3. Teacher installs mobile app
4. Teacher logs in with same credentials as main system
5. Teacher's assigned classes and student lists cached locally

### 2. Daily Workflow
1. Teacher opens app - sees list of assigned classes
2. Teacher selects class and marks attendance (offline)
3. Multiple classes can be marked throughout the day
4. At end of day, teacher connects to office WiFi
5. App auto-discovers main system
6. Teacher taps "Sync" - all marked attendance uploads
7. Main system validates and imports data
8. Conflicts resolved (if any)

### 3. Data Structures for Sync

#### Sync Payload (Teacher → Main)
```json
{
  "deviceId": "uuid-of-device",
  "teacherId": 123,
  "syncTimestamp": "2025-01-15T16:30:00Z",
  "attendanceRecords": [
    {
      "studentId": 456,
      "classId": 1,
      "sectionId": 2,
      "date": "2025-01-15",
      "status": "present",
      "remarks": "Late by 10 mins",
      "markedAt": "2025-01-15T08:15:00Z",
      "academicYear": "2024-2025"
    }
  ]
}
```

#### Sync Response (Main → Teacher)
```json
{
  "success": true,
  "processed": 45,
  "conflicts": 2,
  "errors": [],
  "syncToken": "next-sync-token-for-incremental"
}
```

## Database Schema Changes Required

### Main System - New Tables

#### 1. `SyncDevices` Table
```sql
CREATE TABLE sync_devices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  device_id TEXT UNIQUE NOT NULL,        -- UUID from mobile device
  device_name TEXT,                       -- User-friendly name
  teacher_id INTEGER REFERENCES staff(id),
  last_sync_at DATETIME,
  is_active BOOLEAN DEFAULT true,
  registered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  ip_address TEXT,                        -- Last known IP
  sync_token TEXT                         -- For incremental sync
);
```

#### 2. `SyncLogs` Table (for audit)
```sql
CREATE TABLE sync_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  device_id TEXT REFERENCES sync_devices(device_id),
  teacher_id INTEGER,
  sync_type TEXT,                         -- 'upload', 'download', 'full'
  records_count INTEGER,
  status TEXT,                            -- 'success', 'partial', 'failed'
  error_message TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Mobile App - Tables

#### 1. `CachedClasses` Table
```sql
CREATE TABLE cached_classes (
  id INTEGER PRIMARY KEY,
  class_id INTEGER NOT NULL,
  section_id INTEGER NOT NULL,
  class_name TEXT NOT NULL,
  section_name TEXT NOT NULL,
  total_students INTEGER DEFAULT 0,
  last_synced_at DATETIME
);
```

#### 2. `CachedStudents` Table
```sql
CREATE TABLE cached_students (
  id INTEGER PRIMARY KEY,
  student_id INTEGER NOT NULL,
  class_id INTEGER NOT NULL,
  section_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  roll_number TEXT,
  photo BLOB,                            -- Optional: cached thumbnail
  is_active BOOLEAN DEFAULT true
);
```

#### 3. `PendingAttendance` Table
```sql
CREATE TABLE pending_attendance (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  student_id INTEGER NOT NULL,
  class_id INTEGER NOT NULL,
  section_id INTEGER NOT NULL,
  date TEXT NOT NULL,                    -- YYYY-MM-DD
  status TEXT NOT NULL,                  -- present, absent, late, leave
  remarks TEXT,
  marked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  synced BOOLEAN DEFAULT false,
  sync_attempts INTEGER DEFAULT 0
);
```

#### 4. `SyncConfig` Table
```sql
CREATE TABLE sync_config (
  key TEXT PRIMARY KEY,
  value TEXT,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
-- Keys: 'main_system_ip', 'teacher_token', 'last_sync', 'device_id'
```

---

## Implementation Phases

---

# Phase 1: Foundation & Main System Server
**Estimated Duration: 2-3 weeks**
**Priority: CRITICAL - Must be completed first**

## Phase 1 Goals
1. Add database tables for sync device management
2. Implement HTTP server in main system with mDNS broadcasting
3. Create authentication endpoints for teacher devices
4. Add device management UI in main system settings

## Phase 1 Files to Create/Modify

### New Files (Main System)
```
lib/
├── sync/
│   ├── models/
│   │   ├── sync_device.dart           # Sync device model
│   │   ├── sync_payload.dart          # Sync request/response models
│   │   └── sync_config.dart           # Server configuration
│   ├── server/
│   │   ├── sync_server.dart           # HTTP server implementation (shelf)
│   │   ├── server_routes.dart         # API route definitions
│   │   └── mdns_broadcaster.dart      # mDNS service discovery
│   ├── services/
│   │   ├── sync_device_service.dart   # Device CRUD operations
│   │   ├── sync_processor.dart        # Process incoming sync data
│   │   └── conflict_resolver.dart     # Handle data conflicts
│   └── ui/
│       ├── sync_management_screen.dart    # Manage connected devices
│       ├── device_list_tile.dart          # Device list item UI
│       └── sync_logs_screen.dart          # View sync history
└── database/tables/
    └── sync_tables.dart               # New tables: SyncDevices, SyncLogs
```

### Modified Files (Main System)
```
lib/
├── database/
│   ├── app_database.dart              # Add new sync tables
│   └── tables/tables.dart             # Export sync_tables
├── features/settings/
│   └── screens/settings_screen.dart   # Add "Sync Devices" menu item
└── core/constants/
    └── app_constants.dart             # Add sync server port constants
```

## Phase 1 Technical Specifications

### 1.1 HTTP Server Implementation (shelf package)

**Dependencies to add to pubspec.yaml:**
```yaml
dependencies:
  shelf: ^1.4.1
  shelf_router: ^1.1.4
  multicast_dns: ^0.3.2+7  # mDNS for service discovery
  network_info_plus: ^4.0.2  # Get local IP address
```

**API Endpoints:**

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login` | Teacher login with credentials |
| GET | `/api/v1/teacher/classes` | Get assigned classes for teacher |
| GET | `/api/v1/class/{id}/students` | Get students in class/section |
| POST | `/api/v1/sync/attendance` | Upload attendance records |
| GET | `/api/v1/sync/status` | Check sync status |
| POST | `/api/v1/device/register` | Register new device |
| POST | `/api/v1/device/unregister` | Unregister device |

### 1.2 mDNS Service Discovery

**Service Name:** `_edux-sync._tcp`

**TXT Records:**
- `version`: App version
- `school`: School name (from settings)
- `port`: Server port (default 8181)

### 1.3 Authentication Flow

```
1. Teacher App ──POST /api/v1/auth/login──► Main System
   {username, password, deviceId, deviceName}

2. Main System validates credentials

3. Main System checks if device is registered
   - If not: Auto-register or require admin approval (configurable)

4. Main System returns:
   {
     "success": true,
     "token": "temporary-sync-token",
     "teacherId": 123,
     "teacherName": "John Doe",
     "expiresAt": "2025-01-15T18:00:00Z"
   }
```

## Phase 1 UI Mockups

### Sync Management Screen (Main System)
```
┌─────────────────────────────────────────────┐
│  Settings > Connected Devices          [+Add]│
├─────────────────────────────────────────────┤
│                                              │
│  Server Status: 🟢 Running (Port 8181)       │
│                                              │
│  ┌─────────────────────────────────────┐    │
│  │ 📱 John's Phone (Samsung)           │    │
│  │ Teacher: John Doe (Mathematics)     │    │
│  │ Last Sync: Today, 4:30 PM           │    │
│  │ Status: Active                      │    │
│  │ [View Logs] [Revoke Access]         │    │
│  └─────────────────────────────────────┘    │
│                                              │
│  ┌─────────────────────────────────────┐    │
│  │ 📱 Sarah's Tablet (iPad)            │    │
│  │ Teacher: Sarah Khan (Science)       │    │
│  │ Last Sync: Yesterday, 5:15 PM       │    │
│  │ Status: Inactive (7 days)           │    │
│  │ [View Logs] [Revoke Access]         │    │
│  └─────────────────────────────────────┘    │
│                                              │
└─────────────────────────────────────────────┘
```

## Phase 1 Success Criteria
- [ ] Main system can start/stop HTTP server
- [ ] Server broadcasts itself via mDNS
- [ ] Teachers can login via API with same credentials
- [ ] Device registration works
- [ ] Admin can view and manage connected devices
- [ ] Sync logs are recorded

---

# Phase 2: Teacher Mobile App - Core Structure
**Estimated Duration: 3-4 weeks**
**Priority: CRITICAL - Builds on Phase 1**

## Phase 2 Goals
1. Create new Flutter project for teacher mobile app
2. Implement local database (Drift/SQLite)
3. Create authentication and caching layer
4. Implement server discovery (mDNS client)
5. Build basic UI structure

## Phase 2 Project Structure

```
edux_teacher_app/                    # New Flutter project
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── utils/
│   │   │   ├── network_utils.dart
│   │   │   └── sync_utils.dart
│   │   └── widgets/
│   │       └── common_widgets.dart
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── tables/
│   │   │   ├── cached_classes.dart
│   │   │   ├── cached_students.dart
│   │   │   ├── pending_attendance.dart
│   │   │   └── sync_config.dart
│   │   └── dao/
│   │       ├── class_dao.dart
│   │       ├── student_dao.dart
│   │       ├── attendance_dao.dart
│   │       └── sync_dao.dart
│   ├── models/
│   │   ├── teacher.dart
│   │   ├── class_section.dart
│   │   ├── student.dart
│   │   ├── attendance_record.dart
│   │   └── sync_models.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── sync_provider.dart
│   │   ├── classes_provider.dart
│   │   └── attendance_provider.dart
│   ├── services/
│   │   ├── discovery_service.dart      # mDNS discovery
│   │   ├── sync_service.dart           # HTTP client for sync
│   │   ├── auth_service.dart           # Local auth handling
│   │   └── offline_manager.dart        # Handle offline state
│   └── screens/
│       ├── splash_screen.dart
│       ├── login_screen.dart
│       ├── home_screen.dart
│       ├── class_list_screen.dart
│       ├── mark_attendance_screen.dart
│       ├── sync_screen.dart
│       └── settings_screen.dart
├── android/
├── ios/
├── pubspec.yaml
└── README.md
```

## Phase 2 Dependencies

```yaml
name: edux_teacher_app
description: Teacher Attendance App for EduX

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.5.1

  # Database (Drift)
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.21
  path_provider: ^2.1.3
  path: ^1.9.0

  # Network
  dio: ^5.4.0                    # HTTP client
  multicast_dns: ^0.3.2+7        # mDNS discovery
  connectivity_plus: ^5.0.2      # Network status

  # UI
  google_fonts: ^6.2.1
  lucide_icons: ^0.257.0
  flutter_animate: ^4.5.0
  shimmer: ^3.0.0

  # Utilities
  uuid: ^4.4.0
  intl: ^0.19.0
  shared_preferences: ^2.2.2
  crypto: ^3.0.3
  json_annotation: ^4.9.0

  # Security
  flutter_secure_storage: ^9.0.0  # Store auth tokens

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  drift_dev: ^2.18.0
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  json_serializable: ^6.8.0
```

## Phase 2 Key Features

### 2.1 Server Discovery
- Auto-discover main system on same network
- Show list of discovered EduX servers
- Allow manual IP entry as fallback

### 2.2 Offline-First Architecture
- All data cached locally in SQLite
- Attendance marked locally first
- Sync queue for pending operations
- Works completely offline after initial login

### 2.3 Authentication
- Login with same credentials as main system
- Secure token storage
- Auto-refresh tokens
- Biometric authentication (optional)

## Phase 2 UI Flow

```
[Splash] → [Login] → [Home]
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
   [My Classes]    [Sync Status]    [Settings]
         │
         ▼
   [Class Detail]
         │
         ▼
   [Mark Attendance]
```

## Phase 2 Success Criteria
- [ ] Teacher app can discover main system
- [ ] Login works with main system credentials
- [ ] Classes and students cached locally
- [ ] Attendance can be marked offline
- [ ] Basic sync flow works

---

# Phase 3: Teacher Mobile App - Attendance UI
**Estimated Duration: 2-3 weeks**
**Priority: HIGH - Core user experience**

## Phase 3 Goals
1. Build intuitive attendance marking UI optimized for mobile
2. Implement quick actions (mark all present, etc.)
3. Add attendance history view
4. Implement smart defaults and optimizations

## Phase 3 UI Specifications

### 3.1 Home Screen
```
┌─────────────────────────────────────────────┐
│  EduX Teacher              🔔 ⚙️             │
├─────────────────────────────────────────────┤
│                                              │
│  Welcome, John!                              │
│  📅 Monday, January 15, 2025                 │
│                                              │
│  ┌─────────────────────────────────────┐    │
│  │ 🔄 Sync Status                      │    │
│  │ 3 classes pending sync              │    │
│  │ [Sync Now]                          │    │
│  └─────────────────────────────────────┘    │
│                                              │
│  My Classes Today:                           │
│                                              │
│  ┌─────────────────────────────────────┐    │
│  │ Class 10-A  •  Period 1             │    │
│  │ Mathematics                         │    │
│  │ ✅ Attendance Marked (32/32)        │    │
│  │ [View] [Edit]                       │    │
│  └─────────────────────────────────────┘    │
│                                              │
│  ┌─────────────────────────────────────┐    │
│  │ Class 9-B  •  Period 3              │    │
│  │ Mathematics                         │    │
│  │ ⚠️  Not Marked                      │    │
│  │ [Mark Attendance]                   │    │
│  └─────────────────────────────────────┘    │
│                                              │
└─────────────────────────────────────────────┘
```

### 3.2 Mark Attendance Screen
```
┌─────────────────────────────────────────────┐
│  ← Mark Attendance                     Save │
├─────────────────────────────────────────────┤
│                                              │
│  Class 9-B • Mathematics                     │
│  📅 Jan 15, 2025    ⏰ 10:30 AM             │
│                                              │
│  Quick Actions:                              │
│  [All Present] [All Absent] [Reset]         │
│                                              │
│  Students (32):                              │
│  ┌─────────────────────────────────────┐    │
│  │ 1. Ali Ahmad           [P] [A] [L]  │    │
│  │    Roll: 101                        │    │
│  └─────────────────────────────────────┘    │
│  ┌─────────────────────────────────────┐    │
│  │ 2. Fatima Khan         [P] [A] [L]  │    │
│  │    Roll: 102                        │    │
│  └─────────────────────────────────────┘    │
│  ┌─────────────────────────────────────┐    │
│  │ 3. Muhammad Ali        [P] [A] [L]  │    │
│  │    Roll: 103            ★ Late      │    │
│  │    [Add Remark...]                  │    │
│  └─────────────────────────────────────┘    │
│                                              │
│  [+ Add Student to Class]                    │
│                                              │
└─────────────────────────────────────────────┘
```

**Legend:**
- [P] = Present button (green when selected)
- [A] = Absent button (red when selected)
- [L] = Late button (orange when selected)
- ★ = Remarks added

### 3.3 Sync Screen
```
┌─────────────────────────────────────────────┐
│  ← Sync with Main System                     │
├─────────────────────────────────────────────┤
│                                              │
│  📶 Connected to:                            │
│  Main Office Computer (192.168.1.100)        │
│  Status: Connected ✅                        │
│                                              │
│  Sync Summary:                               │
│  ┌─────────────────────────────────────┐    │
│  │ Today's Attendance                  │    │
│  │                                     │    │
│  │ • Class 10-A: 32 records   ✅       │    │
│  │ • Class 9-B: 30 records    ✅       │    │
│  │ • Class 8-A: 28 records    ⏳       │    │
│  │                                     │    │
│  │ Pending: 1 class (28 students)      │    │
│  └─────────────────────────────────────┘    │
│                                              │
│  [           SYNC NOW           ]           │
│                                              │
│  Last Sync: Today, 3:45 PM                   │
│  Synced by: You (John Doe)                   │
│                                              │
│  [View Sync History]                         │
│                                              │
└─────────────────────────────────────────────┘
```

## Phase 3 Optimizations

### Smart Defaults
1. **Auto-mark Present**: When marking starts, all students default to present (reduces taps)
2. **Remember Previous**: Show yesterday's status as starting point
3. **Quick Actions**: Swipe gestures for common actions
4. **Bulk Operations**: Mark range of students at once

### Offline Indicators
- Clear visual indicator when offline
- Show "will sync when connected" message
- Badge on sync icon showing pending count

## Phase 3 Success Criteria
- [ ] Can mark attendance for a class in under 30 seconds
- [ ] Quick actions work reliably
- [ ] Offline indicators are clear
- [ ] Sync UI shows progress and results
- [ ] History view works

---

# Phase 4: Advanced Sync & Conflict Resolution
**Estimated Duration: 2-3 weeks**
**Priority: HIGH - Data integrity**

## Phase 4 Goals
1. Implement robust conflict detection and resolution
2. Add incremental sync (only changed data)
3. Handle edge cases (duplicate records, deleted students, etc.)
4. Add retry logic and error handling

## Phase 4 Technical Specifications

### 4.1 Conflict Scenarios

| Scenario | Resolution Strategy |
|----------|---------------------|
| Same attendance marked by teacher & office | Show both, let admin decide |
| Student transferred after cache | Flag for review, don't delete data |
| Attendance locked in main system | Show error, suggest admin unlock |
| Duplicate sync request | Idempotent: use studentId + date as key |
| Device clock wrong | Use server timestamp as authoritative |
| Network interruption mid-sync | Resume from checkpoint |

### 4.2 Conflict Resolution UI

When conflicts detected during sync:
```
┌─────────────────────────────────────────────┐
│  ⚠️  Sync Complete with Conflicts           │
├─────────────────────────────────────────────┤
│                                              │
│  2 conflicts need your attention:            │
│                                              │
│  ┌─────────────────────────────────────┐    │
│  │ Class 10-A • Jan 15 • Ali Ahmad     │    │
│  │                                     │    │
│  │ Your marking:  PRESENT              │    │
│  │ Office record: ABSENT               │    │
│  │                                     │    │
│  │ [Keep Mine]  [Use Office]  [Ask Admin]    │
│  └─────────────────────────────────────┘    │
│                                              │
│  [Review All Conflicts]                      │
│                                              │
└─────────────────────────────────────────────┘
```

### 4.3 Retry Logic

```dart
class SyncRetryPolicy {
  static const maxRetries = 3;
  static const retryDelays = [2, 5, 10]; // seconds
  
  Future<T> retry<T>(Future<T> Function() operation) async {
    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: retryDelays[attempt]));
      }
    }
    throw StateError('Unreachable');
  }
}
```

## Phase 4 Success Criteria
- [ ] All conflict scenarios handled gracefully
- [ ] Incremental sync works (faster subsequent syncs)
- [ ] Retry logic handles temporary failures
- [ ] Clear error messages for all failure modes
- [ ] Admin can resolve conflicts from main system

---

# Phase 5: Testing, Polish & Deployment
**Estimated Duration: 2 weeks**
**Priority: MEDIUM - Quality assurance**

## Phase 5 Goals
1. Comprehensive testing (unit, integration, e2e)
2. Performance optimization
3. Security hardening
4. Documentation and deployment guides

## Phase 5 Testing Strategy

### 5.1 Test Scenarios

| Test | Description |
|------|-------------|
| Unit Tests | DAO operations, sync logic, conflict resolution |
| Integration Tests | Server-Client communication, database migrations |
| E2E Tests | Complete user flows: login → mark → sync |
| Network Tests | Offline mode, slow connections, interruptions |
| Security Tests | Token validation, unauthorized access attempts |
| Load Tests | Multiple teachers syncing simultaneously |

### 5.2 Device Testing Matrix

| Device | OS Version | Screen Size | Priority |
|--------|-----------|-------------|----------|
| Samsung Galaxy A54 | Android 14 | 6.4" | High |
| Xiaomi Redmi Note 12 | Android 13 | 6.67" | High |
| Google Pixel 7 | Android 14 | 6.3" | Medium |
| Samsung Tab A9+ | Android 13 | 11" | Medium |
| iPhone 13 (if flutter) | iOS 17 | 6.1" | Low |

## Phase 5 Success Criteria
- [ ] >90% test coverage on critical paths
- [ ] App works on all target devices
- [ ] Performance: Mark attendance < 2s load, Sync < 5s for 50 records
- [ ] Security audit passed
- [ ] Documentation complete

---

# Appendix A: API Specification

## Authentication

### POST /api/v1/auth/login
**Request:**
```json
{
  "username": "teacher1",
  "password": "securePass123",
  "deviceId": "uuid-v4-from-device",
  "deviceName": "John's Samsung",
  "appVersion": "1.0.0"
}
```

**Response (Success):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "teacherId": 123,
  "teacherName": "John Doe",
  "email": "john@school.edu",
  "photoUrl": "/api/v1/teacher/123/photo",
  "permissions": ["mark_attendance", "view_students"],
  "tokenExpiry": "2025-01-15T18:00:00Z"
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "Invalid credentials",
  "errorCode": "AUTH_INVALID_CREDENTIALS"
}
```

## Data Endpoints

### GET /api/v1/teacher/classes
**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "classes": [
    {
      "classId": 1,
      "sectionId": 2,
      "className": "Class 10",
      "sectionName": "A",
      "subjectName": "Mathematics",
      "isClassTeacher": true,
      "totalStudents": 32
    }
  ]
}
```

### GET /api/v1/class/{classId}/{sectionId}/students
**Response:**
```json
{
  "students": [
    {
      "studentId": 456,
      "name": "Ali Ahmad",
      "rollNumber": "101",
      "photoUrl": "/api/v1/student/456/photo",
      "gender": "male"
    }
  ],
  "lastUpdated": "2025-01-15T08:00:00Z"
}
```

### POST /api/v1/sync/attendance
**Request:**
```json
{
  "syncId": "unique-sync-request-id",
  "records": [
    {
      "studentId": 456,
      "classId": 1,
      "sectionId": 2,
      "date": "2025-01-15",
      "status": "present",
      "remarks": "Late by 5 mins",
      "markedAt": "2025-01-15T08:30:00Z"
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "processed": 1,
  "created": 1,
  "updated": 0,
  "conflicts": 0,
  "errors": [],
  "serverTimestamp": "2025-01-15T16:30:00Z"
}
```

---

# Appendix B: Security Considerations

## Network Security
1. **Local Network Only**: Server only binds to local network interfaces
2. **Token-based Auth**: Short-lived JWT tokens (4-hour expiry)
3. **HTTPS Optional**: Can use self-signed certs if needed
4. **Rate Limiting**: Max 100 requests/minute per device

## Data Security
1. **Token Storage**: Use flutter_secure_storage (Keychain/Keystore)
2. **No Sensitive Data in Cache**: Don't store passwords, only tokens
3. **Clear Cache on Logout**: Wipe all local data
4. **Biometric Lock**: Optional fingerprint/PIN for app access

## Device Security
1. **Device Registration**: Each device must be registered
2. **Revocation**: Admin can revoke device access instantly
3. **Auto-lock**: App locks after 5 minutes of inactivity

---

# Appendix C: Deployment Guide (Summary)

## Main System Setup
1. Update to version with sync support
2. Go to Settings > Connected Devices
3. Start Sync Server
4. Note the server IP address shown

## Teacher App Setup
1. Install APK from school admin
2. Open app, grant network permissions
3. App auto-discovers server (or enter IP manually)
4. Login with teacher credentials
5. Download assigned classes
6. Ready to use!

## Daily Workflow
1. Teacher marks attendance throughout day
2. At end of day, ensure on school WiFi
3. Open app, go to Sync tab
4. Tap "Sync Now"
5. Done!

---

**Document Version:** 1.0  
**Last Updated:** 2025-01-15  
**Status:** Ready for Implementation
