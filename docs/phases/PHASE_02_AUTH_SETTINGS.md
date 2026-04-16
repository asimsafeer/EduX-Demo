# Phase 2: Authentication & Settings

## Goals
- School setup wizard for first-time configuration
- User management with role-based access
- Application settings
- Backup and restore functionality

---

## Tasks

### 2.1 School Setup Wizard

First-time setup flow that appears when no school data exists.

**Screens:**
1. Welcome Screen - Introduction to EduX
2. School Information - Name, address, contact
3. Logo Upload - School logo with preview
4. Academic Year - Start/end dates, working days
5. Admin Account - Create first admin user
6. Completion - Summary and finish

**Files:**
```
lib/features/settings/
├── screens/
│   └── setup_wizard/
│       ├── setup_wizard_screen.dart
│       ├── welcome_step.dart
│       ├── school_info_step.dart
│       ├── logo_step.dart
│       ├── academic_year_step.dart
│       ├── admin_account_step.dart
│       └── completion_step.dart
├── controllers/
│   └── setup_wizard_controller.dart
└── widgets/
    └── wizard_progress_indicator.dart
```

---

### 2.2 Login Screen

**Features:**
- Username/password input
- Remember me option
- Forgot password (reset via admin)
- Show/hide password toggle

**File:** `lib/features/auth/screens/login_screen.dart`

```dart
// UI Components
- School logo at top
- Username TextField
- Password TextField with visibility toggle
- "Remember me" checkbox
- Login button (primary action)
- Footer with app version
```

---

### 2.3 User Management

**CRUD Operations:**
- List all users with filters
- Create new user
- Edit user details
- Activate/deactivate user
- Reset password

**Roles & Permissions:**

| Permission | Admin | Principal | Teacher | Accountant |
|------------|-------|-----------|---------|------------|
| Dashboard | ✅ | ✅ | ✅ | ✅ |
| Students (View) | ✅ | ✅ | ✅ | ✅ |
| Students (Edit) | ✅ | ✅ | ❌ | ❌ |
| Attendance | ✅ | ✅ | ✅ | ❌ |
| Exams (Entry) | ✅ | ✅ | ✅ | ❌ |
| Exams (Reports) | ✅ | ✅ | ✅ | ❌ |
| Fees | ✅ | ✅ | ❌ | ✅ |
| Staff | ✅ | ✅ | ❌ | ❌ |
| Settings | ✅ | ❌ | ❌ | ❌ |
| Backup | ✅ | ❌ | ❌ | ❌ |

**Files:**
```
lib/features/settings/
├── screens/
│   ├── user_management_screen.dart
│   └── user_form_screen.dart
├── controllers/
│   └── user_management_controller.dart
└── widgets/
    ├── user_list_tile.dart
    └── role_badge.dart
```

---

### 2.4 Settings Dashboard

**Sections:**

1. **School Settings**
   - School information
   - Logo management
   - Contact details

2. **Academic Settings**
   - Academic year configuration
   - Working days
   - School timings

3. **User Management**
   - User list and management
   - Role configuration

4. **Print Settings**
   - Report header/footer
   - Page size
   - Logo on prints

5. **Backup & Restore**
   - Manual backup
   - Auto backup schedule
   - Restore from backup
   - Export to USB

**File:** `lib/features/settings/screens/settings_screen.dart`

---

### 2.5 Backup System

**Features:**
1. **Manual Backup** - Create backup on demand
2. **Auto Backup** - Scheduled daily/weekly backups
3. **Restore** - Restore from any backup point
4. **Export** - Save backup to USB/external drive
5. **Import** - Load backup from external source

**Backup Contents:**
- SQLite database file
- School logo
- Student photos (if any)
- Compressed as ZIP file

**Files:**
```
lib/services/
├── backup_service.dart
└── file_service.dart

lib/features/settings/
├── screens/
│   └── backup_screen.dart
├── controllers/
│   └── backup_controller.dart
└── widgets/
    ├── backup_list_tile.dart
    └── backup_schedule_dialog.dart
```

**Implementation:**
```dart
class BackupService {
  Future<File> createBackup() async {
    final dbPath = await getDatabasePath();
    final backupDir = await getBackupDirectory();
    final timestamp = DateTime.now().toIso8601String();
    final backupName = 'edux_backup_$timestamp.zip';
    
    // Create ZIP with database and assets
    // Return backup file
  }
  
  Future<void> restoreBackup(File backupFile) async {
    // Extract ZIP
    // Validate database
    // Replace current database
    // Reload app
  }
  
  Future<void> exportToExternal(File backup) async {
    // Use file_picker to select destination
    // Copy backup file
  }
}
```

---

## Database Additions

### Activity Logs Table
```dart
class ActivityLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().nullable().references(Users, #id)();
  TextColumn get action => text()(); // login, logout, create, update, delete
  TextColumn get module => text()(); // students, fees, attendance, etc.
  TextColumn get details => text().nullable()();
  TextColumn get ipAddress => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

### Backup Metadata Table
```dart
class Backups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fileName => text()();
  TextColumn get filePath => text()();
  IntColumn get fileSize => integer()();
  TextColumn get type => text()(); // manual, auto
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

---

## UI Components

### Settings Card
```dart
class SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  
  // Rounded card with icon, title, subtitle
  // Right arrow indicator
  // Hover effect
}
```

### User List Tile
```dart
class UserListTile extends StatelessWidget {
  final User user;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  
  // Avatar with initials
  // Name and role
  // Status indicator
  // Action buttons
}
```

---

## Verification

1. **Setup Wizard**
   - Start app with empty database
   - Complete all wizard steps
   - Verify school settings saved
   - Verify admin account created

2. **Login**
   - Login with admin credentials
   - Verify "Remember me" works
   - Verify incorrect password shows error

3. **User Management**
   - Create user for each role
   - Login with each role
   - Verify permission restrictions

4. **Backup**
   - Create manual backup
   - Verify backup file created
   - Delete database, restore from backup
   - Verify data restored correctly
