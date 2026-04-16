# EduX School Management System - Complete Codebase Analysis

## Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Project Structure](#2-project-structure)
3. [Database Layer (Drift)](#3-database-layer-drift)
4. [State Management (Riverpod)](#4-state-management-riverpod)
5. [Routing System (GoRouter)](#5-routing-system-gorouter)
6. [Authentication & RBAC](#6-authentication--rbac)
7. [UI/Theme System](#7-uitheme-system)
8. [Key Modules](#8-key-modules)
9. [Sync System](#9-sync-system)
10. [Licensing System](#10-licensing-system)
11. [App Flow](#11-app-flow)

---

## 1. Architecture Overview

EduX is a **comprehensive offline-first school management system** built with Flutter. It follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  (Screens, Widgets, Forms, Charts, Dialogs)                  │
├─────────────────────────────────────────────────────────────┤
│                     STATE LAYER (Riverpod)                   │
│  (Providers, Notifiers, AsyncValue management)              │
├─────────────────────────────────────────────────────────────┤
│                    SERVICE LAYER                             │
│  (Business Logic, PDF Generation, Import/Export, Sync)      │
├─────────────────────────────────────────────────────────────┤
│                   REPOSITORY LAYER                           │
│  (Data Access Objects, Query Builders)                      │
├─────────────────────────────────────────────────────────────┤
│                    DATA LAYER (Drift)                        │
│  (SQLite Database, Tables, Migrations, Relations)           │
└─────────────────────────────────────────────────────────────┘
```

### Key Architectural Decisions:
- **Offline-first**: All data stored locally in SQLite via Drift
- **Desktop-first design**: Optimized for Windows/Linux/Mac with custom window chrome
- **Modular licensing**: Features can be locked/unlocked based on license
- **Real-time sync**: Built-in HTTP server for teacher app connectivity
- **RBAC**: Role-based access control for different user types

---

## 2. Project Structure

```
lib/
├── core/                          # Core utilities shared across app
│   ├── constants/                 # App constants, enums
│   ├── extensions/                # Dart extensions (DateTime, String, etc.)
│   ├── theme/                     # AppTheme, colors, text styles
│   ├── utils/                     # Utilities (PDF, Excel, Toast, etc.)
│   ├── widgets/                   # Reusable widgets (buttons, loaders, etc.)
│   └── screens/                   # Shared screens (PDF preview)
│
├── database/                      # Database layer
│   ├── app_database.dart          # Main Drift database class
│   ├── app_database.g.dart        # Generated code
│   └── tables/                    # Table definitions
│       ├── school_tables.dart     # SchoolSettings, Users, AcademicYears
│       ├── student_tables.dart    # Students, Guardians, Enrollments
│       ├── academic_tables.dart   # Classes, Sections, Subjects, Timetable
│       ├── attendance_tables.dart # StudentAttendance, StaffAttendance
│       ├── exam_tables.dart       # Exams, Marks, Grades
│       ├── fee_tables.dart        # Invoices, Payments, Concessions
│       ├── staff_tables.dart      # Staff, Roles, Payroll, Leave
│       ├── system_tables.dart     # ActivityLogs, Backups, Settings
│       ├── expense_tables.dart    # Expenses
│       ├── canteen_tables.dart    # Canteen, Transactions
│       └── sync_tables.dart       # SyncDevices, SyncLogs
│
├── features/                      # Feature modules
│   ├── splash/                    # Splash screen
│   ├── setup/                     # School setup wizard
│   ├── auth/                      # Login, account recovery
│   ├── shell/                     # App shell with sidebar
│   ├── dashboard/                 # Dashboard with charts/stats
│   ├── settings/                  # Settings screens
│   └── reports/                   # Report generation
│
├── screens/                       # Module screens (legacy organization)
│   ├── students/                  # Student management screens
│   ├── staff/                     # Staff management screens
│   ├── academics/                 # Class/Subject/Timetable screens
│   ├── attendance/                # Attendance marking screens
│   ├── exams/                     # Exam management screens
│   ├── fees/                      # Fee management screens
│   ├── guardians/                 # Guardian management
│   ├── expenses/                  # Expense tracking
│   └── canteen/                   # Canteen management
│
├── providers/                     # Riverpod providers
│   ├── auth_provider.dart         # Authentication state
│   ├── dashboard_provider.dart    # Dashboard data
│   ├── student_provider.dart      # Student data
│   └── ...
│
├── repositories/                  # Data access layer
│   ├── student_repository.dart
│   ├── class_repository.dart
│   └── ...
│
├── services/                      # Business logic services
│   ├── auth_service.dart          # Authentication
│   ├── student_service.dart       # Student operations
│   ├── invoice_service.dart       # Invoice generation
│   ├── license_service.dart       # License management
│   ├── rbac_service.dart          # Role-based access control
│   └── ...
│
├── router/                        # Navigation
│   └── app_router.dart            # GoRouter configuration
│
├── sync/                          # Teacher app sync system
│   ├── models/                    # Sync DTOs
│   ├── server/                    # HTTP server
│   ├── services/                  # Sync processing
│   ├── ui/                        # Sync management UI
│   └── providers/                 # Sync providers
│
└── main.dart                      # Application entry point
```

---

## 3. Database Layer (Drift)

### Database Architecture
- **Technology**: Drift (formerly moor) - type-safe SQLite wrapper
- **File**: `edux_database_v2.db` stored in app documents
- **Schema Version**: 12
- **Pattern**: Singleton with `AppDatabase.instance`

### Table Categories:

#### Core Tables (school_tables.dart)
| Table | Purpose |
|-------|---------|
| `SchoolSettings` | School profile, branding, contact info |
| `Users` | Login accounts with role-based permissions |
| `AcademicYears` | Academic session management |

#### Student Tables (student_tables.dart)
| Table | Purpose |
|-------|---------|
| `Students` | Complete student profiles |
| `Guardians` | Parent/guardian information |
| `StudentGuardians` | Many-to-many relationship |
| `Enrollments` | Class enrollment history |

#### Academic Tables (academic_tables.dart)
| Table | Purpose |
|-------|---------|
| `Classes` | School class definitions (Playgroup to Class 10) |
| `Sections` | Class sections (A, B, C) |
| `Subjects` | Subject definitions |
| `ClassSubjects` | Subject assignments per class |
| `TimetableSlots` | Weekly timetable entries |
| `PeriodDefinitions` | School period timings |

#### Fee Tables (fee_tables.dart)
| Table | Purpose |
|-------|---------|
| `FeeTypes` | Fee categories (Tuition, Transport, etc.) |
| `FeeStructures` | Class-wise fee amounts |
| `Invoices` | Generated fee invoices |
| `InvoiceItems` | Line items in invoices |
| `AdHocInvoiceItems` | Custom/miscellaneous charges |
| `Payments` | Payment transactions |
| `Concessions` | Student fee discounts |

### Database Migrations
```dart
// Current strategy: Destructive migration on version change
onUpgrade: (Migrator m, int from, int to) async {
  if (from < 12) {
    // Drop all tables and recreate
    final allTables = m.database.allTables.toList();
    for (final table in allTables) {
      await m.database.customStatement(
        'DROP TABLE IF EXISTS "${table.actualTableName}"',
      );
    }
    await m.createAll();
  }
}
```

### Seeding Data
The database automatically seeds:
1. **Staff Roles**: Admin, Principal, Teacher, Accountant, Staff
2. **Fee Types**: Tuition, Registration, Security, Exam, Transport, Lab, Stationery
3. **Leave Types**: Casual, Sick, Earned, Unpaid
4. **Grade Settings**: A+ (90-100%) to F (0-39%)
5. **Number Sequences**: Admission, Invoice, Receipt, Employee prefixes

---

## 4. State Management (Riverpod)

### Provider Architecture
EduX uses **Flutter Riverpod** for reactive state management:

```dart
// Service Providers (Singletons)
final authServiceProvider = Provider<AuthService>((ref) => AuthService.instance());
final rbacServiceProvider = Provider<RbacService>((ref) => RbacService());

// State Notifier Providers (Mutable State)
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final activityLogService = ref.watch(activityLogServiceProvider);
  return CurrentUserNotifier(authService, activityLogService);
});

// Async Data Providers (Future/Stream)
final schoolSettingsProvider = FutureProvider<SchoolSetting?>((ref) async {
  final db = AppDatabase.instance;
  return await db.getSchoolSettings();
});

// Family Providers (Parametrized)
final studentProvider = FutureProvider.family<Student?, int>((ref, id) async {
  final service = ref.watch(studentServiceProvider);
  return await service.getStudentById(id);
});
```

### Key Providers:

| Provider | Type | Purpose |
|----------|------|---------|
| `currentUserProvider` | StateNotifier | Authentication state |
| `permissionsProvider` | Provider | RBAC permission checks |
| `dashboardProvider` | StateNotifier | Dashboard statistics |
| `schoolSettingsProvider` | FutureProvider | School configuration |
| `syncEventsProvider` | StreamProvider | Real-time sync updates |

---

## 5. Routing System (GoRouter)

### Router Configuration
```dart
static final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: true,
  redirect: _handleRedirect,  // Auth & permission checks
  routes: [
    // Public routes
    GoRoute(path: AppRoutes.splash, builder: ...),
    GoRoute(path: AppRoutes.login, builder: ...),
    
    // Protected shell routes
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: AppRoutes.dashboard, ...),
        GoRoute(path: AppRoutes.students, ...),
        // ... more routes
      ],
    ),
  ],
);
```

### Route Protection
Routes are protected with **multi-layer security**:

1. **Authentication Check**: Redirects to login if not authenticated
2. **RBAC Permission Check**: Validates user has required permission
3. **Module License Check**: Verifies module is unlocked

```dart
// Route permission mapping
if (path.startsWith(AppRoutes.students)) {
  if (path.contains('/add') || path.contains('/edit')) {
    requiredPermission = RbacService.manageStudents;
  } else {
    requiredPermission = RbacService.viewStudents;
  }
}

// Check permission
if (!rbacService.hasPermission(user, requiredPermission)) {
  return AppRoutes.dashboard;  // Redirect if no permission
}
```

---

## 6. Authentication & RBAC

### Authentication Flow

```
User Input → AuthService.login() → Password Hash Check → 
Update lastLogin → Save Session (optional) → Navigate to Dashboard
```

### Password Security
- **Hashing**: SHA-256 with unique salt per user
- **Salt**: 32-byte cryptographically secure random
- **Validation**: Minimum 6 chars, must contain letter + number

```dart
String hashPassword(String password, String salt) {
  final saltedPassword = password + salt;
  final bytes = utf8.encode(saltedPassword);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
```

### Session Management
- **Remember Me**: 30-day session stored in SharedPreferences
- **Token Storage**: `session_user_id` + `session_expiry`
- **Auto-Restore**: Session restored on app launch

### RBAC (Role-Based Access Control)

#### User Roles:
| Role | Default Permissions |
|------|---------------------|
| Admin | All permissions |
| Principal | View all, manage students/staff/academics |
| Teacher | View students/academics, manage attendance/exams |
| Accountant | View students, manage fees/expenses, view reports |

#### Permission Constants:
```dart
// View permissions
static const String viewStudents = 'view_students';
static const String viewStaff = 'view_staff';
static const String viewFees = 'view_fees';

// Manage permissions
static const String manageStudents = 'manage_students';
static const String manageStaff = 'manage_staff';
static const String manageFees = 'manage_fees';
```

#### Permission Resolution Order:
1. System Admin check (has all permissions)
2. Explicit permissions from `users.permissions` column
3. Role-based default permissions (if no explicit permissions)

---

## 7. UI/Theme System

### Theme Architecture
- **Design System**: Material 3 with custom color scheme
- **Colors**: Primary (indigo), Secondary (teal), Accent (amber)
- **Typography**: Inter font family with defined text styles
- **Components**: Consistent cards, buttons, inputs, dialogs

### Color Palette
```dart
class AppColors {
  static const Color primary = Color(0xFF4F46E5);      // Indigo
  static const Color secondary = Color(0xFF0D9488);   // Teal
  static const Color accent = Color(0xFFF59E0B);      // Amber
  static const Color success = Color(0xFF10B981);     // Emerald
  static const Color warning = Color(0xFFF59E0B);     // Amber
  static const Color error = Color(0xFFEF4444);       // Red
  static const Color info = Color(0xFF3B82F6);        // Blue
}
```

### Responsive Design
- **Desktop-first**: Minimum window size 1200x700
- **Adaptive Layouts**: Grid counts adjust based on screen width
- **Collapsible Sidebar**: 240px (expanded) / 72px (collapsed)

### Window Management (Desktop)
```dart
// Custom title bar with window controls
WindowOptions(
  size: Size(1400, 900),
  minimumSize: Size(1200, 700),
  titleBarStyle: TitleBarStyle.hidden,  // Custom chrome
)
```

---

## 8. Key Modules

### 8.1 Student Management
- **Features**: CRUD, bulk import (Excel), photo upload, guardian linking
- **Key Tables**: Students, Guardians, StudentGuardians, Enrollments
- **Screens**: StudentList, StudentForm, StudentProfile, BulkImport

### 8.2 Staff Management
- **Features**: Staff profiles, roles, attendance, leave, payroll
- **Key Tables**: Staff, StaffRoles, LeaveRequests, Payroll
- **Screens**: StaffList, StaffForm, StaffProfile, StaffAttendance, StaffPayroll

### 8.3 Academics
- **Features**: Classes, sections, subjects, timetable, period config
- **Key Tables**: Classes, Sections, Subjects, ClassSubjects, TimetableSlots
- **Screens**: AcademicsScreen, TimetableScreen, ClassSubjectAssignment

### 8.4 Attendance
- **Features**: Mark attendance, reports, calendar view, history
- **Key Tables**: StudentAttendance, StaffAttendance, DailyAttendanceStatus
- **Screens**: AttendanceScreen, MarkAttendance, AttendanceReport

### 8.5 Fee Management
- **Features**: Fee structure, invoice generation, payment collection, defaulters
- **Key Tables**: FeeTypes, FeeStructures, Invoices, Payments, Concessions
- **Screens**: FeeDashboard, FeeStructure, InvoicesList, PaymentCollection

### 8.6 Exam Management
- **Features**: Exam creation, marks entry, result analysis, report cards
- **Key Tables**: Exams, ExamSubjects, StudentMarks, GradeSettings
- **Screens**: ExamsScreen, MarksEntry, ResultAnalysis, ReportCard

---

## 9. Sync System

### Overview
The sync system enables **teacher mobile apps** to connect to the desktop app and sync attendance data.

### Architecture
```
Teacher App (Mobile)          EduX Desktop (Server)
       |                              |
       |---- HTTP POST /auth/login -->|
       |<--- Token + Permissions -----|
       |                              |
       |---- GET /teacher/classes --->|
       |<--- Class list --------------|
       |                              |
       |---- GET /class/{id}/students>|
       |<--- Student list ------------|
       |                              |
       |---- POST /sync/attendance --->|
       |<--- Sync response -----------|
```

### Server Implementation
- **Framework**: Shelf (Dart HTTP server)
- **Port**: 8181 (configurable)
- **Security**: Token-based auth, rate limiting, CORS

### Key Endpoints:
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Server health check |
| `/api/v1/auth/login` | POST | Teacher authentication |
| `/api/v1/teacher/classes` | GET | Get assigned classes |
| `/api/v1/class/{id}/{section}/students` | GET | Get class students |
| `/api/v1/sync/attendance` | POST | Upload attendance |
| `/api/v1/sync/status` | GET | Server status |

### Sync Processing
```dart
// SyncProcessor processes attendance records
Future<SyncResponse> processSync(SyncRequest request, String ipAddress) {
  // 1. Validate each record
  // 2. Check for conflicts (different status exists)
  // 3. Create or update attendance records
  // 4. Return results with conflict info
}
```

### Conflict Resolution
- **Detection**: Same student, same date, different status
- **Resolution**: Office status takes precedence, conflicts logged
- **UI**: Conflict viewer in sync management screen

---

## 10. Licensing System

### License Model
- **Module-based**: Individual modules can be locked/unlocked
- **Expiry-based**: Time-limited licenses with automatic expiration
- **Integrity protection**: SHA-256 hash prevents tampering

### License Status
```dart
enum AppLicenseStatus {
  licensed,        // Valid license with approved modules
  expired,         // License expired or no license
  pendingRequest,  // Request submitted, awaiting approval
}
```

### Modules
| Module ID | Description |
|-----------|-------------|
| `student_management` | Add/edit students |
| `staff_management` | Staff operations |
| `academic_management` | Classes/subjects |
| `attendance_tracking` | Mark/view attendance |
| `exam_management` | Exams and marks |
| `fee_management` | Invoices and payments |
| `reporting` | Reports and analytics |

### License Validation Flow
```
1. Get true time from NTP (prevent time tampering)
2. Check integrity hash
3. Verify expiration
4. Check module approval
5. Grant/deny access
```

### Firestore Integration
- **Registration**: School registration on setup
- **License Requests**: Submitted to `license_requests` collection
- **License Approval**: NovaByte Hub approves and writes to `licenses` collection
- **Auto-refresh**: Desktop app polls for license updates

---

## 11. App Flow

### Application Startup Flow
```
main()
  ├── Initialize Flutter bindings
  ├── Initialize AppDatabase (singleton)
  ├── Setup ErrorLogger
  ├── Initialize Desktop Window (if desktop)
  ├── Run App with ProviderScope
  │
  └── SplashScreen
       ├── Show animation (2 seconds)
       ├── Check if school setup complete
       │    ├── NO → Go to SchoolSetupScreen
       │    └── YES → Continue
       ├── Check license status
       │    ├── expired → Go to LicenseRequestScreen
       │    ├── pending → Allow (grace period)
       │    └── licensed → Continue
       ├── Verify admin user exists
       │    ├── NO → Reset and go to Setup
       │    └── YES → Go to LoginScreen
       │
LoginScreen
  ├── Enter credentials
  ├── AuthService.login() validates
  ├── Save session (if Remember Me)
  ├── Log activity
  └── Navigate to Dashboard

Dashboard
  ├── Load statistics (auto-refresh every 30s)
  ├── Display charts (attendance, fees, admissions)
  ├── Show alerts and recent activity
  └── Provide quick action shortcuts
```

### Navigation Flow
```
AppShell (persistent sidebar)
  ├── Dashboard
  ├── Students
  │    ├── List
  │    ├── Add/Edit
  │    ├── Profile
  │    └── Import
  ├── Staff
  ├── Academics
  ├── Attendance
  ├── Exams
  ├── Fees
  ├── Reports
  ├── Expenses
  ├── Canteen
  └── Settings
       ├── School Profile
       ├── Academic Settings
       ├── User Management
       ├── Backup & Restore
       ├── Print Settings
       └── Sync Devices
```

---

## Summary

EduX is a **production-ready, enterprise-grade school management system** with:

1. **Robust Architecture**: Clean separation, offline-first, modular design
2. **Comprehensive Features**: Students, staff, academics, fees, exams, attendance
3. **Security**: Authentication, RBAC, license protection, data integrity
4. **Modern UI**: Material 3, responsive, desktop-optimized
5. **Connectivity**: Built-in sync server for mobile teacher apps
6. **Licensing**: Flexible module-based licensing system
7. **Data Management**: Full backup/restore, import/export capabilities

The codebase follows Flutter/Dart best practices with type safety, proper error handling, and maintainable code structure.
