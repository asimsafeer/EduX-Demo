# Phase 3: Student Management

## Goals
- Complete CRUD for students
- Guardian management with linking
- Class enrollment and history
- Advanced search and filtering
- PDF and Excel export
- Bulk import from Excel

---

## Tasks

### 3.1 Student List Screen

**Features:**
- Paginated data table
- Search by name, admission number
- Filter by class, section, gender, status
- Sort by any column
- Quick actions (view, edit, delete)
- Export buttons (PDF, Excel)

**Layout:**
```
┌─────────────────────────────────────────────────────────┐
│ Student Management                    [+ Add Student]   │
├─────────────────────────────────────────────────────────┤
│ [🔍 Search...     ] [Class ▾] [Section ▾] [Status ▾]   │
├─────────────────────────────────────────────────────────┤
│ ☑ │ # │ Adm No │ Name      │ Class  │ Gender │ Actions │
├───┼───┼────────┼───────────┼────────┼────────┼─────────┤
│ ☐ │ 1 │ 2024-1 │ Ahmed Ali │ 5-A    │ Male   │ 👁 ✏️ 🗑 │
│ ☐ │ 2 │ 2024-2 │ Sara Khan │ 5-B    │ Female │ 👁 ✏️ 🗑 │
├─────────────────────────────────────────────────────────┤
│ Showing 1-25 of 150 students    [◀ 1 2 3 4 5 ... ▶]    │
└─────────────────────────────────────────────────────────┘
```

**Files:**
```
lib/features/students/
├── screens/
│   ├── student_list_screen.dart
│   ├── student_form_screen.dart
│   └── student_profile_screen.dart
├── controllers/
│   ├── student_list_controller.dart
│   └── student_form_controller.dart
├── widgets/
│   ├── student_data_table.dart
│   ├── student_filters.dart
│   ├── student_search_bar.dart
│   └── student_card.dart
└── repositories/
    └── student_repository.dart
```

---

### 3.2 Student Form Screen

**Sections:**

1. **Personal Information**
   - First Name* (required)
   - Last Name*
   - Date of Birth
   - Gender* (dropdown)
   - Blood Group
   - Religion
   - Nationality

2. **Contact Information**
   - Address
   - Phone
   - Email

3. **Academic Information**
   - Admission Number* (auto-generated option)
   - Admission Date*
   - Class* (dropdown)
   - Section* (dropdown)

4. **Medical Information**
   - Medical notes
   - Allergies
   - Special needs

5. **Photo Upload**
   - Drag & drop or click to upload
   - Preview with crop option
   - Store as blob in database

**Validation:**
- First name: Required, min 2 chars
- Last name: Required, min 2 chars
- Admission number: Required, unique
- Gender: Required
- Class: Required
- Section: Required
- Email: Valid email format (if provided)
- Phone: Valid phone format (if provided)

---

### 3.3 Student Profile Screen

**Tabbed Layout:**

1. **Overview Tab**
   - Photo and basic info card
   - Quick stats (attendance %, current class)
   - Guardian information
   - Enrollment history

2. **Attendance Tab**
   - Calendar view of attendance
   - Summary statistics
   - Monthly breakdown

3. **Academics Tab**
   - Current class info
   - Exam results summary
   - Report cards access

4. **Fees Tab**
   - Fee status summary
   - Payment history
   - Outstanding dues

5. **Documents Tab**
   - Uploaded documents
   - Generated reports

---

### 3.4 Guardian Management

**Tables:**
```dart
class Guardians extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get firstName => text().withLength(max: 50)();
  TextColumn get lastName => text().withLength(max: 50)();
  TextColumn get relation => text()(); // father, mother, guardian, other
  TextColumn get phone => text()();
  TextColumn get alternatePhone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get occupation => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get cnic => text().nullable()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class StudentGuardians extends Table {
  IntColumn get studentId => integer().references(Students, #id)();
  IntColumn get guardianId => integer().references(Guardians, #id)();
  
  @override
  Set<Column> get primaryKey => {studentId, guardianId};
}
```

**Features:**
- Add multiple guardians per student
- Set primary guardian
- Quick add from student form
- Search existing guardians

---

### 3.5 Enrollment Tracking

**Table:**
```dart
class Enrollments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId => integer().references(Students, #id)();
  IntColumn get classId => integer().references(Classes, #id)();
  IntColumn get sectionId => integer().references(Sections, #id)();
  TextColumn get academicYear => text()();
  TextColumn get rollNumber => text().nullable()();
  DateTimeColumn get enrollmentDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get status => text()(); // active, promoted, transferred, withdrawn
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

**Features:**
- Track class changes over years
- Roll number assignment
- Transfer history

---

### 3.6 Export Functionality

**PDF Export:**
```dart
class StudentPdfService {
  Future<Uint8List> generateStudentList({
    required List<Student> students,
    required SchoolSettings school,
  }) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(school),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildTitle('Student List'),
          _buildTable(students),
        ],
      ),
    );
    
    return pdf.save();
  }
  
  Future<Uint8List> generateStudentProfile(Student student) async {
    // Individual student profile PDF
  }
}
```

**Excel Export:**
```dart
class StudentExcelService {
  Future<List<int>> exportStudentList(List<Student> students) async {
    final excel = Excel.createExcel();
    final sheet = excel['Students'];
    
    // Headers
    sheet.appendRow([
      'Admission No',
      'First Name',
      'Last Name',
      'Class',
      'Section',
      'Gender',
      'Date of Birth',
      'Phone',
      'Email',
      'Guardian Name',
      'Guardian Phone',
    ]);
    
    // Data rows
    for (final student in students) {
      sheet.appendRow([...]);
    }
    
    return excel.encode()!;
  }
}
```

---

### 3.7 Bulk Import

**Excel Template:**
| Column | Required | Format |
|--------|----------|--------|
| Admission No | Yes | Text |
| First Name | Yes | Text |
| Last Name | Yes | Text |
| Class | Yes | Text (must match) |
| Section | Yes | Text (must match) |
| Gender | Yes | Male/Female |
| Date of Birth | No | DD/MM/YYYY |
| Phone | No | Text |
| Email | No | Email |
| Guardian Name | No | Text |
| Guardian Phone | No | Text |
| Guardian Relation | No | Father/Mother/Guardian |

**Import Flow:**
1. Download template button
2. Upload filled Excel file
3. Validation step (show errors)
4. Preview imported data
5. Confirm import
6. Success summary

**Files:**
```
lib/features/students/
├── screens/
│   └── bulk_import_screen.dart
├── services/
│   └── student_import_service.dart
└── widgets/
    ├── import_preview_table.dart
    └── import_error_list.dart
```

---

## Repository Pattern

```dart
abstract class StudentRepository {
  Future<List<Student>> getAll();
  Future<List<Student>> getByClass(int classId);
  Future<List<Student>> search(String query);
  Future<Student?> getById(int id);
  Future<Student?> getByAdmissionNumber(String admissionNumber);
  Future<int> create(StudentCompanion student);
  Future<bool> update(int id, StudentCompanion student);
  Future<bool> delete(int id);
  Future<int> count({int? classId, int? sectionId});
}

class StudentRepositoryImpl implements StudentRepository {
  final AppDatabase db;
  
  StudentRepositoryImpl(this.db);
  
  @override
  Future<List<Student>> getAll() {
    return db.select(db.students).get();
  }
  
  @override
  Future<List<Student>> search(String query) {
    return (db.select(db.students)
      ..where((s) => 
        s.firstName.contains(query) |
        s.lastName.contains(query) |
        s.admissionNumber.contains(query)
      ))
      .get();
  }
  
  // ... other methods
}
```

---

## Verification

1. **Student CRUD**
   - Add 5 students with complete information
   - Edit student details
   - View student profile
   - Delete student (with confirmation)

2. **Guardian Management**
   - Add guardians to student
   - Link existing guardian
   - Set primary guardian
   - View guardian on profile

3. **Search & Filter**
   - Search by name (partial match)
   - Search by admission number
   - Filter by class
   - Filter by section
   - Combine filters

4. **Export**
   - Export filtered list to PDF
   - Export to Excel
   - Verify data accuracy

5. **Bulk Import**
   - Download template
   - Fill with 10 test students
   - Import and verify
   - Test validation errors
