# Phase 5: Attendance System

## Goals
- Calendar-based attendance interface
- Class-wise bulk attendance marking
- Multiple status options with remarks
- Comprehensive attendance reports

---

## Tasks

### 5.1 Attendance Calendar

**Features:**
- Month view calendar
- Visual indicators for marked days
- Quick navigation between months
- Today highlight

**Calendar Indicators:**
- Green: All present
- Yellow: Partial attendance
- Red: High absence
- Gray: Holiday/Weekend
- Empty: Not marked

---

### 5.2 Class-wise Attendance Screen

**Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ Attendance                                                  │
├─────────────────────────────────────────────────────────────┤
│ Date: [📅 03 Feb 2026]  Class: [5 ▾]  Section: [A ▾]       │
├─────────────────────────────────────────────────────────────┤
│ Quick Actions: [✓ Mark All Present] [✗ Mark All Absent]   │
├─────────────────────────────────────────────────────────────┤
│ Present: 28  │  Absent: 3  │  Late: 1  │  Leave: 0        │
├─────────────────────────────────────────────────────────────┤
│  # │ Roll No │ Student Name    │ Status          │ Remarks │
├────┼─────────┼─────────────────┼─────────────────┼─────────┤
│  1 │ 5A-01   │ Ahmed Ali       │ [P] [A] [L] [LV]│ [📝]    │
│  2 │ 5A-02   │ Sara Khan       │ [●] [A] [L] [LV]│ [📝]    │
│  3 │ 5A-03   │ Usman Raza      │ [P] [●] [L] [LV]│ Sick    │
│  4 │ 5A-04   │ Fatima Noor     │ [P] [A] [●] [LV]│ Late 10m│
│ ...│ ...     │ ...             │ ...             │ ...     │
├─────────────────────────────────────────────────────────────┤
│                           [💾 Save Attendance]              │
└─────────────────────────────────────────────────────────────┘
```

**Status Options:**
| Status | Code | Color | Icon |
|--------|------|-------|------|
| Present | P | Green | ✓ |
| Absent | A | Red | ✗ |
| Late | L | Orange | ⏰ |
| Leave | LV | Blue | 📋 |

---

### 5.3 Database Tables

```dart
class StudentAttendance extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId => integer().references(Students, #id)();
  IntColumn get classId => integer().references(Classes, #id)();
  IntColumn get sectionId => integer().references(Sections, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get status => text()(); // present, absent, late, leave
  TextColumn get remarks => text().nullable()();
  IntColumn get markedBy => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  List<String> get customConstraints => [
    'UNIQUE(student_id, date)'
  ];
}
```

---

### 5.4 Attendance Service

```dart
class AttendanceService {
  Future<void> markAttendance({
    required int studentId,
    required DateTime date,
    required String status,
    String? remarks,
    required int markedBy,
  });
  
  Future<void> markBulkAttendance({
    required List<int> studentIds,
    required DateTime date,
    required String status,
    required int markedBy,
  });
  
  Future<List<StudentAttendance>> getClassAttendance({
    required int classId,
    required int sectionId,
    required DateTime date,
  });
  
  Future<AttendanceStats> getStudentStats({
    required int studentId,
    required DateTime startDate,
    required DateTime endDate,
  });
  
  Future<AttendanceStats> getClassStats({
    required int classId,
    required int sectionId,
    required DateTime startDate,
    required DateTime endDate,
  });
}

class AttendanceStats {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int leaveDays;
  
  double get attendancePercentage => 
    (presentDays + lateDays) / totalDays * 100;
}
```

---

### 5.5 Reports

**Available Reports:**

1. **Daily Attendance Report**
   - Date-wise class attendance
   - Absent student list
   - Overall statistics

2. **Monthly Attendance Report**
   - Calendar grid view
   - Student-wise monthly summary
   - Class trends

3. **Student Attendance History**
   - Individual student view
   - Absence pattern
   - Guardian notification trigger

4. **Class Attendance Summary**
   - Class-wise comparison
   - Section-wise breakdown
   - Trend analysis

**PDF Report Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│                      [SCHOOL LOGO]                          │
│                    Al Madina School                         │
│              Daily Attendance Report                        │
│                   Date: 03 Feb 2026                         │
├─────────────────────────────────────────────────────────────┤
│ Class: 5-A                                                  │
│ Total Students: 32 | Present: 28 | Absent: 3 | Late: 1     │
├─────────────────────────────────────────────────────────────┤
│  # │ Roll No │ Student Name    │ Status  │ Remarks         │
├────┼─────────┼─────────────────┼─────────┼─────────────────┤
│  1 │ 5A-01   │ Ahmed Ali       │ Present │                 │
│  2 │ 5A-02   │ Sara Khan       │ Present │                 │
│  3 │ 5A-03   │ Usman Raza      │ Absent  │ Sick            │
│ ...│ ...     │ ...             │ ...     │ ...             │
├─────────────────────────────────────────────────────────────┤
│ Marked by: Admin User                   Time: 09:15 AM     │
└─────────────────────────────────────────────────────────────┘
```

---

### 5.6 Statistics Dashboard

**Widgets:**
- Today's attendance summary card
- Weekly attendance trend chart
- Class-wise attendance comparison
- Low attendance alerts

**Alerts:**
- Students with attendance < 75%
- Classes with high absence rate
- Unmarked attendance for today

---

## Files Structure

```
lib/features/attendance/
├── screens/
│   ├── attendance_screen.dart
│   ├── class_attendance_screen.dart
│   ├── attendance_calendar_screen.dart
│   ├── attendance_report_screen.dart
│   └── student_attendance_screen.dart
├── controllers/
│   ├── attendance_controller.dart
│   └── attendance_report_controller.dart
├── widgets/
│   ├── attendance_calendar.dart
│   ├── attendance_status_button.dart
│   ├── attendance_student_row.dart
│   ├── attendance_stats_card.dart
│   └── attendance_chart.dart
├── services/
│   └── attendance_service.dart
└── repositories/
    └── attendance_repository.dart
```

---

## Verification

1. **Mark Attendance**
   - Select date and class
   - Mark individual status
   - Use "Mark All Present"
   - Add remarks for absent/late

2. **Edit Attendance**
   - Go to previous date
   - Change status
   - Verify update

3. **Reports**
   - Generate daily report PDF
   - Generate monthly report
   - Check statistics accuracy

4. **Statistics**
   - Verify present/absent counts
   - Check percentage calculation
   - Test low attendance alerts
