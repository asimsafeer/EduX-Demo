# Phase 6: Examination System

## Goals
- Flexible exam creation and configuration
- Easy marks entry with validation
- Professional report card generation
- Grade settings and result analysis

---

## Tasks

### 6.1 Exam Types

| Type | Description |
|------|-------------|
| Unit Test | Small topic-based tests |
| Monthly Test | End of month assessment |
| Term Exam | Mid-term/quarterly exams |
| Annual Exam | End of year final exam |
| Practice Test | Non-graded assessments |

---

### 6.2 Database Tables

```dart
class Exams extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text().withLength(max: 100)();
  TextColumn get type => text()(); // unit, monthly, term, annual
  TextColumn get academicYear => text()();
  IntColumn get classId => integer().references(Classes, #id)();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  // draft, active, completed
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ExamSubjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get examId => integer().references(Exams, #id)();
  IntColumn get subjectId => integer().references(Subjects, #id)();
  RealColumn get maxMarks => real()();
  RealColumn get passingMarks => real()();
  DateTimeColumn get examDate => dateTime().nullable()();
  TextColumn get examTime => text().nullable()();
}

class StudentMarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get examId => integer().references(Exams, #id)();
  IntColumn get examSubjectId => integer().references(ExamSubjects, #id)();
  IntColumn get studentId => integer().references(Students, #id)();
  RealColumn get marksObtained => real().nullable()();
  BoolColumn get isAbsent => boolean().withDefault(const Constant(false))();
  TextColumn get remarks => text().nullable()();
  IntColumn get enteredBy => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class GradeSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get grade => text().withLength(max: 5)();
  RealColumn get minPercentage => real()();
  RealColumn get maxPercentage => real()();
  RealColumn get gpa => real()();
  TextColumn get remarks => text().nullable()();
  IntColumn get displayOrder => integer()();
}
```

---

### 6.3 Exam Creation Flow

**Step 1: Basic Information**
- Exam name
- Exam type (dropdown)
- Class (dropdown)
- Date range

**Step 2: Subject Configuration**
- Select subjects for exam
- Set max marks per subject
- Set passing marks per subject
- Optional: exam date/time per subject

**Step 3: Review & Publish**
- Summary view
- Publish exam (makes active)

---

### 6.4 Marks Entry Screen

**Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ Marks Entry                                                 │
├─────────────────────────────────────────────────────────────┤
│ Exam: [Annual Exam 2026 ▾]  Subject: [Mathematics ▾]       │
│ Class: 5-A                  Max Marks: 100  Pass: 40       │
├─────────────────────────────────────────────────────────────┤
│  # │ Roll No │ Student Name    │ Marks  │ Absent │ Remarks │
├────┼─────────┼─────────────────┼────────┼────────┼─────────┤
│  1 │ 5A-01   │ Ahmed Ali       │ [  85] │ [  ]   │ [📝]    │
│  2 │ 5A-02   │ Sara Khan       │ [  92] │ [  ]   │ [📝]    │
│  3 │ 5A-03   │ Usman Raza      │ [    ] │ [✓]    │ Sick    │
│  4 │ 5A-04   │ Fatima Noor     │ [  78] │ [  ]   │ [📝]    │
│ ...│ ...     │ ...             │ ...    │ ...    │ ...     │
├─────────────────────────────────────────────────────────────┤
│ Entered: 30/32              [💾 Save] [📊 Complete Entry]  │
└─────────────────────────────────────────────────────────────┘
```

**Validation:**
- Marks cannot exceed max marks
- Marks cannot be negative
- Either marks or absent must be set
- Warn on unusual entries (0 or max)

---

### 6.5 Report Card Generation

**Report Card Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│                      [SCHOOL LOGO]                          │
│                    Al Madina School                         │
│                    REPORT CARD                              │
│                   Annual Exam 2026                          │
├─────────────────────────────────────────────────────────────┤
│ Name: Ahmed Ali              Roll No: 5A-01                 │
│ Class: 5-A                   Admission No: 2024-001         │
│ Father's Name: Ali Khan      Date of Birth: 15 May 2014    │
├─────────────────────────────────────────────────────────────┤
│ SUBJECT PERFORMANCE                                         │
├─────────────────────────────────────────────────────────────┤
│  Subject        │ Max Marks │ Obtained │ Grade │ Remarks   │
├─────────────────┼───────────┼──────────┼───────┼───────────┤
│ English         │   100     │    85    │   A   │ Good      │
│ Urdu            │   100     │    78    │   B+  │           │
│ Mathematics     │   100     │    92    │   A+  │ Excellent │
│ Science         │   100     │    80    │   A   │           │
│ Social Studies  │   100     │    75    │   B+  │           │
│ Islamiat        │    50     │    42    │   A   │           │
│ Computer        │    50     │    45    │   A+  │           │
├─────────────────┼───────────┼──────────┼───────┼───────────┤
│ TOTAL           │   600     │   497    │   A   │           │
├─────────────────────────────────────────────────────────────┤
│ Percentage: 82.83%    GPA: 3.7    Rank: 5/32               │
├─────────────────────────────────────────────────────────────┤
│ Teacher's Remarks: Excellent performance. Keep it up!       │
│ Principal's Signature: ___________  Date: ___________      │
│ Parent's Signature: ___________                             │
└─────────────────────────────────────────────────────────────┘
```

**Features:**
- Individual report card
- Bulk generation for class
- Print directly
- Save as PDF

---

### 6.6 Grade Settings

**Default Grades:**
| Grade | Min % | Max % | GPA | Remarks |
|-------|-------|-------|-----|---------|
| A+ | 90 | 100 | 4.0 | Outstanding |
| A | 80 | 89 | 3.7 | Excellent |
| B+ | 70 | 79 | 3.3 | Very Good |
| B | 60 | 69 | 3.0 | Good |
| C+ | 50 | 59 | 2.5 | Satisfactory |
| C | 40 | 49 | 2.0 | Average |
| F | 0 | 39 | 0.0 | Fail |

**Customization:**
- Add/edit/delete grades
- Modify percentage ranges
- Custom remarks

---

### 6.7 Result Analysis

**Charts & Statistics:**
- Class average per subject
- Pass/fail ratio
- Grade distribution pie chart
- Top performers list
- Subject-wise comparison

**Analysis Screen:**
```
┌─────────────────────────────────────────────────────────────┐
│ Result Analysis: Annual Exam 2026 - Class 5                │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│ │  Pass: 29       │ │  Fail: 3        │ │  Avg: 72.5%     ││
│ │  91%            │ │  9%             │ │                 ││
│ └─────────────────┘ └─────────────────┘ └─────────────────┘│
├─────────────────────────────────────────────────────────────┤
│ Subject-wise Performance                                    │
│ ┌───────────────────────────────────────────────────────┐  │
│ │ [Bar Chart: Subject vs Average Marks]                 │  │
│ └───────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│ Grade Distribution                Top 5 Performers          │
│ ┌───────────────────┐            ┌───────────────────────┐ │
│ │ [Pie Chart]       │            │ 1. Sara Khan - 92%    │ │
│ │ A+: 5, A: 12,     │            │ 2. Ahmed Ali - 89%    │ │
│ │ B+: 8, B: 4,      │            │ 3. Fatima Noor - 87%  │ │
│ │ C: 2, F: 1        │            │ 4. Hassan Malik - 85% │ │
│ └───────────────────┘            │ 5. Zara Ali - 84%     │ │
│                                  └───────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## Files Structure

```
lib/features/exams/
├── screens/
│   ├── exams_screen.dart
│   ├── exam_form_screen.dart
│   ├── marks_entry_screen.dart
│   ├── report_card_screen.dart
│   ├── result_analysis_screen.dart
│   └── grade_settings_screen.dart
├── controllers/
│   ├── exam_controller.dart
│   ├── marks_entry_controller.dart
│   └── result_analysis_controller.dart
├── widgets/
│   ├── exam_card.dart
│   ├── marks_input_row.dart
│   ├── grade_badge.dart
│   ├── result_chart.dart
│   └── report_card_template.dart
├── services/
│   ├── exam_service.dart
│   └── report_card_service.dart
└── repositories/
    ├── exam_repository.dart
    └── marks_repository.dart
```

---

## Verification

1. **Exam Creation**
   - Create annual exam for Class 5
   - Configure 7 subjects
   - Set max/passing marks

2. **Marks Entry**
   - Enter marks for all students
   - Test validation (exceeds max)
   - Mark absent students

3. **Report Cards**
   - Generate individual report card
   - Generate bulk for class
   - Print and save as PDF

4. **Grade Settings**
   - Modify grade ranges
   - Verify grade calculation

5. **Analysis**
   - View class statistics
   - Check chart accuracy
   - Verify top performers
