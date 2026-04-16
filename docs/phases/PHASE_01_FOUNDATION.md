# Phase 1: Foundation & Core Architecture

## Goals
- Set up project structure with clean architecture
- Configure Drift database with all tables
- Implement theme and design system
- Set up navigation framework

---

## Tasks

### 1.1 Dependencies Setup

**File:** `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management & DI
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  
  # Database
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.21
  path_provider: ^2.1.3
  path: ^1.9.0
  
  # UI Components
  google_fonts: ^6.2.1
  lucide_icons: ^0.257.0
  flutter_animate: ^4.5.0
  
  # Export/Import
  pdf: ^3.10.8
  printing: ^5.12.0
  excel: ^4.0.3
  
  # Charts
  fl_chart: ^0.68.0
  
  # File Handling
  file_picker: ^8.0.3
  share_plus: ^9.0.0
  
  # Navigation
  go_router: ^14.1.4
  
  # Desktop
  window_manager: ^0.3.9
  
  # Utils
  uuid: ^4.4.0
  equatable: ^2.0.5
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  drift_dev: ^2.18.0
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
```

---

### 1.2 Project Structure

Create directories:
```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── db_constants.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── utils/
│   │   ├── date_utils.dart
│   │   ├── validators.dart
│   │   └── formatters.dart
│   ├── extensions/
│   │   └── context_extensions.dart
│   └── widgets/
│       ├── app_card.dart
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── app_dropdown.dart
│       ├── loading_overlay.dart
│       ├── empty_state.dart
│       └── data_table_widget.dart
├── database/
│   ├── database.dart
│   └── tables/
│       ├── school_tables.dart
│       ├── student_tables.dart
│       ├── academic_tables.dart
│       ├── attendance_tables.dart
│       ├── exam_tables.dart
│       ├── fee_tables.dart
│       ├── staff_tables.dart
│       └── system_tables.dart
├── features/
│   ├── dashboard/
│   ├── students/
│   ├── academics/
│   ├── attendance/
│   ├── exams/
│   ├── fees/
│   ├── staff/
│   ├── reports/
│   └── settings/
├── models/
├── repositories/
├── services/
└── providers/
```

---

### 1.3 Database Tables

#### School Settings Table
```dart
class SchoolSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get schoolName => text().withLength(max: 200)();
  BlobColumn get logo => blob().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get website => text().nullable()();
  TextColumn get principalName => text().nullable()();
  TextColumn get currencySymbol => text().withDefault(const Constant('PKR'))();
  TextColumn get academicYearStart => text().nullable()();
  TextColumn get academicYearEnd => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### Users Table
```dart
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get username => text().withLength(max: 50).unique()();
  TextColumn get passwordHash => text()();
  TextColumn get fullName => text().withLength(max: 100)();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get role => text()(); // admin, principal, teacher, accountant
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastLogin => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### Students Table
```dart
class Students extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get admissionNumber => text().unique()();
  TextColumn get firstName => text().withLength(max: 50)();
  TextColumn get lastName => text().withLength(max: 50)();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  TextColumn get gender => text()(); // male, female
  TextColumn get bloodGroup => text().nullable()();
  TextColumn get religion => text().nullable()();
  TextColumn get nationality => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  BlobColumn get photo => blob().nullable()();
  TextColumn get medicalInfo => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get admissionDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### Classes Table
```dart
class Classes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 50)();
  TextColumn get level => text()(); // pre-primary, primary, middle, secondary
  IntColumn get displayOrder => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
```

#### Sections Table
```dart
class Sections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId => integer().references(Classes, #id)();
  TextColumn get name => text().withLength(max: 10)(); // A, B, C
  IntColumn get capacity => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
```

---

### 1.4 Theme Configuration

#### Colors
```dart
class AppColors {
  // Primary
  static const primary = Color(0xFF1E3A5F);
  static const primaryLight = Color(0xFF2E5077);
  static const primaryDark = Color(0xFF0F2847);
  
  // Secondary
  static const secondary = Color(0xFF0D9488);
  static const secondaryLight = Color(0xFF14B8A6);
  
  // Accent
  static const accent = Color(0xFFF59E0B);
  
  // Backgrounds
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F5F9);
  
  // Status
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  
  // Text
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textDisabled = Color(0xFF94A3B8);
  
  // Border
  static const border = Color(0xFFE2E8F0);
  static const borderDark = Color(0xFFCBD5E1);
}
```

---

### 1.5 Navigation Setup

Using go_router for navigation with shell route for consistent layout:

```dart
final router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/students', builder: (_, __) => const StudentsScreen()),
        GoRoute(path: '/academics', builder: (_, __) => const AcademicsScreen()),
        GoRoute(path: '/attendance', builder: (_, __) => const AttendanceScreen()),
        GoRoute(path: '/exams', builder: (_, __) => const ExamsScreen()),
        GoRoute(path: '/fees', builder: (_, __) => const FeesScreen()),
        GoRoute(path: '/staff', builder: (_, __) => const StaffScreen()),
        GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);
```

---

## Deliverables

1. ✅ Clean project structure
2. ✅ All dependencies installed
3. ✅ Drift database with core tables
4. ✅ Theme configuration
5. ✅ Base layout with navigation sidebar
6. ✅ Reusable widget library

---

## Verification

```bash
# Build database
dart run build_runner build --delete-conflicting-outputs

# Run app
flutter run -d windows

# Verify
- App launches without errors
- Navigation sidebar works
- Theme colors applied correctly
```
