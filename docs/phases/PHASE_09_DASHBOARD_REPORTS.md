# Phase 9: Dashboard & Reports

## Goals
- Comprehensive dashboard with real-time statistics
- Quick action shortcuts
- Analytics charts and visualizations
- Central reporting system

---

## Tasks

### 9.1 Dashboard Layout

**Main Dashboard:**
```
┌─────────────────────────────────────────────────────────────────────────┐
│ 🏫 Al Madina School                                    👤 Admin User  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │
│  │ 👨‍🎓 Students  │ │ 👨‍🏫 Staff     │ │ 💰 Collection│ │ 📊 Attendance│  │
│  │    450      │ │     22       │ │  PKR 2.5M   │ │    92%       │  │
│  │  +15 new    │ │  Active      │ │  This month │ │  Today       │  │
│  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘  │
│                                                                         │
│  ┌─────────────────────────────────┐ ┌─────────────────────────────────┐│
│  │ 📈 Attendance Trend (Weekly)   │ │ 💵 Fee Collection (Monthly)     ││
│  │ ┌─────────────────────────────┐│ │ ┌─────────────────────────────┐ ││
│  │ │                             ││ │ │                             │ ││
│  │ │     [Line Chart]            ││ │ │    [Bar Chart]              │ ││
│  │ │                             ││ │ │                             │ ││
│  │ └─────────────────────────────┘│ │ └─────────────────────────────┘ ││
│  └─────────────────────────────────┘ └─────────────────────────────────┘│
│                                                                         │
│  QUICK ACTIONS                                                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│  │ + Student│ │ 📋 Attend│ │ 💵 Collect│ │ 📝 Marks │ │ 📊 Report│     │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘     │
│                                                                         │
│  ┌────────────────────────────────┐ ┌────────────────────────────────┐ │
│  │ 🔔 ALERTS                      │ │ 📜 RECENT ACTIVITY             │ │
│  │ • 15 students absent today    │ │ • Admin marked attendance 5-A  │ │
│  │ • 8 fee defaulters (30+ days) │ │ • Payment received: Ahmed Ali  │ │
│  │ • Exam marks pending: Class 7 │ │ • New student enrolled: Sara K │ │
│  │ • 3 leave requests pending    │ │ • Report generated: Fee Summary│ │
│  └────────────────────────────────┘ └────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

---

### 9.2 Statistics Cards

**Card Types:**

| Card | Data | Trend |
|------|------|-------|
| Total Students | Count from students table | vs last month |
| Total Staff | Active staff count | - |
| Fee Collection | Sum from this month | vs last month |
| Attendance Rate | Today's % | vs yesterday |
| Outstanding Fees | Total pending | - |
| Exams Active | Ongoing exams | - |

**Card Component:**
```dart
class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String? subtitle;
  final double? trend; // positive or negative percentage
  
  // Renders a card with icon, value, trend indicator
}
```

---

### 9.3 Charts

**1. Attendance Trend Chart**
- Line chart showing 7-day attendance %
- Separate lines for present/absent
- Tooltips on hover

**2. Fee Collection Chart**
- Bar chart showing monthly collections
- Current year comparison
- Target vs actual

**3. Class Strength Chart**
- Pie chart showing students per level
- Pre-primary, Primary, Middle, Secondary

**4. Grade Distribution**
- Donut chart for recent exam
- Pass/fail ratio

---

### 9.4 Quick Actions

| Action | Destination |
|--------|-------------|
| Add Student | Student form |
| Mark Attendance | Attendance screen |
| Collect Fee | Payment screen |
| Enter Marks | Marks entry |
| Generate Report | Reports screen |
| Backup Data | Backup settings |

---

### 9.5 Alerts System

**Alert Types:**
1. **Attendance Alerts**
   - High absence rate
   - Unmarked attendance

2. **Fee Alerts**
   - Defaulters
   - Collection targets

3. **Academic Alerts**
   - Pending marks entry
   - Low performers

4. **Staff Alerts**  
   - Leave requests
   - Attendance issues

**Alert Storage:**
```dart
class SystemAlerts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // info, warning, error
  TextColumn get category => text()(); // attendance, fee, academic, staff
  TextColumn get title => text()();
  TextColumn get message => text()();
  TextColumn get actionRoute => text().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

---

### 9.6 Activity Feed

**Tracked Activities:**
- Student enrolled/updated
- Attendance marked
- Payment received
- Exam created
- Marks entered
- Report generated
- User login/logout
- Settings changed

**Activity Display:**
```dart
class ActivityTile extends StatelessWidget {
  final String action;
  final String details;
  final String user;
  final DateTime timestamp;
  final IconData icon;
  
  // "Admin marked attendance for Class 5-A"
  // "2 minutes ago"
}
```

---

### 9.7 Reports Center

**Report Categories:**

**Student Reports:**
1. Student List by Class
2. Student List with Guardians
3. Student Contact Directory
4. New Admissions Report
5. Withdrawn Students

**Attendance Reports:**
6. Daily Attendance Summary
7. Monthly Attendance Report
8. Student Attendance History
9. Low Attendance Students
10. Staff Attendance Summary

**Fee Reports:**
11. Fee Collection Summary
12. Daily Collection Report
13. Outstanding Fees Report
14. Concession Report
15. Fee Defaulters List

**Academic Reports:**
16. Class-wise Exam Results
17. Subject-wise Analysis
18. Top Performers List
19. Underperformers List
20. Grade Distribution

**Reports Screen Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ Reports Center                                              │
├─────────────────────────────────────────────────────────────┤
│ [Students] [Attendance] [Fees] [Academics] [Staff]         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 📄 Student List by Class                            │   │
│  │    Get complete list of students filtered by class   │   │
│  │                              [Generate] [Preview]    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 📄 Student Contact Directory                        │   │
│  │    Student and guardian contact information          │   │
│  │                              [Generate] [Preview]    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ...                                                        │
└─────────────────────────────────────────────────────────────┘
```

---

### 9.8 Report Generation Service

```dart
class ReportService {
  Future<Uint8List> generateStudentListReport({
    required int? classId,
    required int? sectionId,
    required ReportFormat format, // pdf, excel
  });
  
  Future<Uint8List> generateAttendanceReport({
    required DateTime startDate,
    required DateTime endDate,
    required int? classId,
    required ReportFormat format,
  });
  
  Future<Uint8List> generateFeeCollectionReport({
    required DateTime startDate,
    required DateTime endDate,
    required ReportFormat format,
  });
  
  // ... more report methods
}
```

---

## Files Structure

```
lib/features/dashboard/
├── screens/
│   └── dashboard_screen.dart
├── widgets/
│   ├── stat_card.dart
│   ├── attendance_chart.dart
│   ├── fee_chart.dart
│   ├── quick_action_grid.dart
│   ├── alert_list.dart
│   └── activity_feed.dart
└── controllers/
    └── dashboard_controller.dart

lib/features/reports/
├── screens/
│   ├── reports_screen.dart
│   └── report_viewer_screen.dart
├── widgets/
│   ├── report_card.dart
│   ├── report_filter_dialog.dart
│   └── report_preview.dart
├── services/
│   ├── report_service.dart
│   └── pdf_templates/
│       ├── student_list_template.dart
│       ├── attendance_template.dart
│       └── fee_template.dart
└── controllers/
    └── reports_controller.dart
```

---

## Verification

1. **Dashboard Stats**
   - Verify student count matches
   - Check fee collection total
   - Confirm attendance percentage

2. **Charts**
   - View attendance trend
   - Check fee chart data
   - Verify class distribution

3. **Quick Actions**
   - Click each action
   - Verify navigation

4. **Alerts**
   - Create conditions for alerts
   - Verify alerts appear
   - Mark as read

5. **Reports**
   - Generate each report type
   - Preview before print
   - Export to PDF/Excel
