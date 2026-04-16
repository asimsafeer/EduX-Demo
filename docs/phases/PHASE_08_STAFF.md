# Phase 8: Staff Management

## Goals
- Complete staff profile management
- Role-based assignments
- Staff attendance tracking
- Leave management
- Basic payroll

---

## Tasks

### 8.1 Database Tables

```dart
class Staff extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get employeeId => text().unique()();
  TextColumn get firstName => text().withLength(max: 50)();
  TextColumn get lastName => text().withLength(max: 50)();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  TextColumn get gender => text()();
  TextColumn get cnic => text().nullable()();
  TextColumn get phone => text()();
  TextColumn get alternatePhone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  BlobColumn get photo => blob().nullable()();
  TextColumn get qualification => text().nullable()();
  TextColumn get experience => text().nullable()();
  TextColumn get designation => text()();
  TextColumn get department => text().nullable()();
  IntColumn get roleId => integer().references(StaffRoles, #id)();
  RealColumn get basicSalary => real()();
  DateTimeColumn get joiningDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  // active, on_leave, resigned, terminated
  TextColumn get bankName => text().nullable()();
  TextColumn get accountNumber => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class StaffRoles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 50).unique()();
  TextColumn get description => text().nullable()();
  BoolColumn get canTeach => boolean().withDefault(const Constant(false))();
}

class StaffAttendance extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get staffId => integer().references(Staff, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get status => text()(); // present, absent, late, leave, half_day
  TextColumn get checkIn => text().nullable()(); // HH:mm format
  TextColumn get checkOut => text().nullable()();
  TextColumn get remarks => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  @override
  List<String> get customConstraints => [
    'UNIQUE(staff_id, date)'
  ];
}

class LeaveTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // sick, casual, annual, maternity
  IntColumn get maxDays => integer()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(true))();
}

class LeaveRequests extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get staffId => integer().references(Staff, #id)();
  IntColumn get leaveTypeId => integer().references(LeaveTypes, #id)();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  IntColumn get totalDays => integer()();
  TextColumn get reason => text()();
  TextColumn get status => text()(); // pending, approved, rejected
  IntColumn get approvedBy => integer().nullable().references(Users, #id)();
  TextColumn get remarks => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class StaffSubjectAssignments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get staffId => integer().references(Staff, #id)();
  IntColumn get classId => integer().references(Classes, #id)();
  IntColumn get sectionId => integer().nullable().references(Sections, #id)();
  IntColumn get subjectId => integer().references(Subjects, #id)();
  TextColumn get academicYear => text()();
}

class Payroll extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get staffId => integer().references(Staff, #id)();
  TextColumn get month => text()(); // 2026-02
  RealColumn get basicSalary => real()();
  RealColumn get allowances => real().withDefault(const Constant(0))();
  RealColumn get deductions => real().withDefault(const Constant(0))();
  RealColumn get netSalary => real()();
  TextColumn get status => text()(); // pending, paid
  DateTimeColumn get paidDate => dateTime().nullable()();
  TextColumn get paymentMode => text().nullable()();
  TextColumn get remarks => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

---

### 8.2 Staff List Screen

**Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ Staff Management                         [+ Add Staff]     │
├─────────────────────────────────────────────────────────────┤
│ [🔍 Search...     ] [Role ▾] [Department ▾] [Status ▾]     │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────┐│
│ │ [👤] Muhammad Ahmed Khan                                ││
│ │     Employee ID: EMP-001    Designation: Principal      ││
│ │     Phone: 0300-1234567     Email: ahmed@school.com     ││
│ │     Status: Active          Joined: Jan 2020            ││
│ │                                [👁️ View] [✏️ Edit]      ││
│ └─────────────────────────────────────────────────────────┘│
│ ┌─────────────────────────────────────────────────────────┐│
│ │ [👤] Fatima Ali                                         ││
│ │     Employee ID: EMP-002    Designation: Senior Teacher ││
│ │     Phone: 0321-7654321     Email: fatima@school.com    ││
│ │     Status: Active          Joined: Aug 2018            ││
│ │                                [👁️ View] [✏️ Edit]      ││
│ └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

---

### 8.3 Staff Roles

**Default Roles:**
| Role | Can Teach | Permissions |
|------|-----------|-------------|
| Principal | No | Full access, approvals |
| Vice Principal | No | Most access, approvals |
| Senior Teacher | Yes | Teaching, attendance, marks |
| Teacher | Yes | Teaching, attendance, marks |
| Accountant | No | Fee management |
| Admin Officer | No | Student records |
| Librarian | No | Library (future) |
| Lab Assistant | No | Lab access |
| Driver | No | Transport |
| Support Staff | No | Limited |

---

### 8.4 Staff Attendance Screen

**Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ Staff Attendance                                            │
├─────────────────────────────────────────────────────────────┤
│ Date: [📅 03 Feb 2026]                                     │
├─────────────────────────────────────────────────────────────┤
│ Quick Actions: [✓ All Present] [Apply Leave]               │
├─────────────────────────────────────────────────────────────┤
│ Present: 18  │  Absent: 2  │  Late: 1  │  Leave: 1         │
├─────────────────────────────────────────────────────────────┤
│  # │ Emp ID  │ Name            │ Status     │ In    │ Out  │
├────┼─────────┼─────────────────┼────────────┼───────┼──────┤
│  1 │ EMP-001 │ Muhammad Ahmed  │ [P][A][L][LV]│ 08:00│      │
│  2 │ EMP-002 │ Fatima Ali      │ [●][A][L][LV]│ 08:05│      │
│  3 │ EMP-003 │ Ali Hassan      │ [P][●][L][LV]│      │      │
│ ...│ ...     │ ...             │ ...        │ ...   │ ...  │
├─────────────────────────────────────────────────────────────┤
│                           [💾 Save Attendance]              │
└─────────────────────────────────────────────────────────────┘
```

---

### 8.5 Leave Management

**Leave Request Flow:**
1. Staff/Admin submits request
2. Request appears in pending list
3. Approver reviews and approves/rejects
4. Leave auto-applies to attendance

**Leave Balance Tracking:**
```
┌─────────────────────────────────────────────────────────────┐
│ Leave Balance: Muhammad Ahmed                               │
├─────────────────────────────────────────────────────────────┤
│ Leave Type    │ Allocated │ Used │ Remaining               │
├───────────────┼───────────┼──────┼─────────────────────────┤
│ Sick Leave    │    10     │   2  │     8                   │
│ Casual Leave  │    12     │   5  │     7                   │
│ Annual Leave  │    15     │   0  │    15                   │
└─────────────────────────────────────────────────────────────┘
```

---

### 8.6 Subject/Class Assignment

**Features:**
- Assign subjects to teachers
- Assign class teacher role
- View teacher workload
- Academic year based

**Assignment Screen:**
```
┌─────────────────────────────────────────────────────────────┐
│ Teaching Assignments: Fatima Ali                           │
├─────────────────────────────────────────────────────────────┤
│ Academic Year: [2025-26 ▾]                                 │
├─────────────────────────────────────────────────────────────┤
│ Class    │ Section │ Subject     │ Periods/Week │ Actions  │
├──────────┼─────────┼─────────────┼──────────────┼──────────┤
│ Class 5  │ A       │ Mathematics │ 6            │ [🗑️]     │
│ Class 5  │ B       │ Mathematics │ 6            │ [🗑️]     │
│ Class 6  │ A       │ Mathematics │ 5            │ [🗑️]     │
├──────────┴─────────┴─────────────┴──────────────┴──────────┤
│ Total Periods/Week: 17                                      │
├─────────────────────────────────────────────────────────────┤
│                               [+ Add Assignment]            │
└─────────────────────────────────────────────────────────────┘
```

---

### 8.7 Payroll Management

**Payroll Process:**
1. Generate monthly payroll sheet
2. Review and adjust (allowances/deductions)
3. Mark as paid
4. Print salary slips

**Salary Slip:**
```
┌─────────────────────────────────────────────────────────────┐
│                    SALARY SLIP                              │
│                  February 2026                              │
├─────────────────────────────────────────────────────────────┤
│ Employee: Fatima Ali                 ID: EMP-002           │
│ Designation: Senior Teacher          Bank: HBL             │
│ Account: 1234-5678-9012                                    │
├─────────────────────────────────────────────────────────────┤
│ EARNINGS                     │ DEDUCTIONS                  │
├──────────────────────────────┼─────────────────────────────┤
│ Basic Salary      50,000     │ Late Deduction     0        │
│ Transport Allow    5,000     │ Absence Deduction  0        │
│ Medical Allow      3,000     │ Advance            0        │
│ Other              0         │ Other              0        │
├──────────────────────────────┼─────────────────────────────┤
│ Total Earnings    58,000     │ Total Deductions   0        │
├─────────────────────────────────────────────────────────────┤
│                         NET SALARY:  PKR 58,000            │
└─────────────────────────────────────────────────────────────┘
```

---

## Files Structure

```
lib/features/staff/
├── screens/
│   ├── staff_screen.dart
│   ├── staff_list_screen.dart
│   ├── staff_form_screen.dart
│   ├── staff_profile_screen.dart
│   ├── staff_attendance_screen.dart
│   ├── leave_management_screen.dart
│   ├── teaching_assignments_screen.dart
│   └── payroll_screen.dart
├── controllers/
│   ├── staff_controller.dart
│   ├── staff_attendance_controller.dart
│   ├── leave_controller.dart
│   └── payroll_controller.dart
├── widgets/
│   ├── staff_card.dart
│   ├── staff_attendance_row.dart
│   ├── leave_request_card.dart
│   ├── assignment_tile.dart
│   └── salary_slip_template.dart
├── services/
│   └── payroll_service.dart
└── repositories/
    ├── staff_repository.dart
    └── leave_repository.dart
```

---

## Verification

1. **Staff CRUD**
   - Add 5 staff members
   - Upload photo
   - Edit details
   - View profile

2. **Staff Attendance**
   - Mark daily attendance
   - Add check-in/out times
   - View monthly summary

3. **Leave Management**
   - Submit leave request
   - Approve/reject leave
   - Check leave balance

4. **Assignments**
   - Assign subjects to teacher
   - View workload

5. **Payroll**
   - Generate monthly payroll
   - Add allowances
   - Print salary slip
