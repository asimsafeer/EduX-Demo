# Phase 4: Academic Management

## Goals
- Class and section configuration
- Subject management with codes
- Timetable builder
- Student promotions

---

## Tasks

### 4.1 Class Management

**Class Levels:**
| Level | Classes |
|-------|---------|
| Pre-Primary | Playgroup, Nursery, KG |
| Primary | Class 1, 2, 3, 4, 5 |
| Middle | Class 6, 7, 8 |
| Secondary | Class 9, 10 |

**Features:**
- Add/edit/delete classes
- Set display order
- Activate/deactivate
- View student count per class

**Screen Layout:**
```
┌─────────────────────────────────────────────────────────┐
│ Academic Management            [+ Add Class]            │
├─────────────────────────────────────────────────────────┤
│ [Classes] [Sections] [Subjects] [Timetable] [Promotion] │
├─────────────────────────────────────────────────────────┤
│ PRE-PRIMARY                                             │
│ ├── Playgroup (A, B) ──── 45 students ──── [Edit]      │
│ ├── Nursery (A, B, C) ─── 62 students ──── [Edit]      │
│ └── KG (A, B) ─────────── 48 students ──── [Edit]      │
│                                                         │
│ PRIMARY                                                 │
│ ├── Class 1 (A, B, C) ─── 75 students ──── [Edit]      │
│ ├── Class 2 (A, B, C) ─── 72 students ──── [Edit]      │
│ ...                                                     │
└─────────────────────────────────────────────────────────┘
```

---

### 4.2 Section Management

**Features:**
- Add sections per class
- Set capacity per section
- Activate/deactivate
- View student count

**UI:**
```dart
// Section Dialog
class SectionFormDialog extends StatelessWidget {
  // Class dropdown (pre-selected if adding from class)
  // Section name (A, B, C, etc.)
  // Capacity field
  // Active toggle
}
```

---

### 4.3 Subject Configuration

**Table:**
```dart
class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(max: 10)();
  TextColumn get name => text().withLength(max: 100)();
  TextColumn get type => text()(); // core, elective, optional
  IntColumn get creditHours => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class ClassSubjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId => integer().references(Classes, #id)();
  IntColumn get subjectId => integer().references(Subjects, #id)();
  IntColumn get teacherId => integer().nullable().references(Staff, #id)();
}
```

**Default Subjects:**
- English, Urdu, Mathematics, Science, Social Studies
- Islamiat, Computer, Art, Physical Education

**Features:**
- Subject list with codes
- Assign subjects to classes
- Assign teacher per class-subject
- Credit hours configuration

---

### 4.4 Timetable Builder

**Table:**
```dart
class TimetableSlots extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId => integer().references(Classes, #id)();
  IntColumn get sectionId => integer().references(Sections, #id)();
  IntColumn get subjectId => integer().references(Subjects, #id)();
  IntColumn get teacherId => integer().nullable().references(Staff, #id)();
  TextColumn get dayOfWeek => text()(); // monday, tuesday, ...
  TextColumn get startTime => text()(); // HH:mm format
  TextColumn get endTime => text()();
  IntColumn get periodNumber => integer()();
}
```

**Features:**
- Weekly grid view
- Drag-and-drop scheduling
- Period configuration
- Break time slots
- Conflict detection

**UI Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ Timetable: Class 5-A                 [Class ▾] [Section ▾] │
├─────────────────────────────────────────────────────────────┤
│       │ Period 1 │ Period 2 │ Break │ Period 3 │ Period 4 │
│       │ 8:00-8:45│ 8:45-9:30│  30m  │10:00-10:45│10:45-11:30│
├───────┼──────────┼──────────┼───────┼──────────┼──────────┤
│ Mon   │ English  │ Math     │       │ Science  │ Urdu     │
│ Tue   │ Math     │ English  │       │ S.Studies│ Computer │
│ Wed   │ Science  │ Urdu     │       │ English  │ Math     │
│ Thu   │ Islamiat │ Math     │       │ Art      │ English  │
│ Fri   │ English  │ Science  │       │ P.E.     │ Urdu     │
│ Sat   │ Math     │ S.Studies│       │ Islamiat │ Computer │
└─────────────────────────────────────────────────────────────┘
```

---

### 4.5 Student Promotions

**Flow:**
1. Select source class and section
2. View student list
3. Select students to promote
4. Choose destination class and section
5. Set academic year
6. Confirm promotion

**Features:**
- Bulk select/deselect
- Exclude failed students
- Keep enrollment history
- Generate roll numbers

**Screen:**
```
┌─────────────────────────────────────────────────────────┐
│ Student Promotion                                       │
├─────────────────────────────────────────────────────────┤
│ From: [Class 5 ▾] [Section A ▾]                        │
│ To:   [Class 6 ▾] [Section A ▾]                        │
│ Academic Year: [2024-2025 ▾]                           │
├─────────────────────────────────────────────────────────┤
│ ☑ Select All (32 students)                             │
├─────────────────────────────────────────────────────────┤
│ [☑] Ahmed Ali ──── Result: Pass (78%) ──── Promote     │
│ [☑] Sara Khan ──── Result: Pass (85%) ──── Promote     │
│ [☐] Usman Raza ─── Result: Fail (38%) ──── Retain      │
│ [☑] Fatima Noor ── Result: Pass (72%) ──── Promote     │
├─────────────────────────────────────────────────────────┤
│ Selected: 31 students                  [Promote Now]    │
└─────────────────────────────────────────────────────────┘
```

---

## Files Structure

```
lib/features/academics/
├── screens/
│   ├── academics_screen.dart (tab container)
│   ├── class_list_screen.dart
│   ├── section_list_screen.dart
│   ├── subject_list_screen.dart
│   ├── timetable_screen.dart
│   └── promotion_screen.dart
├── controllers/
│   ├── class_controller.dart
│   ├── section_controller.dart
│   ├── subject_controller.dart
│   ├── timetable_controller.dart
│   └── promotion_controller.dart
├── widgets/
│   ├── class_tree_view.dart
│   ├── section_form_dialog.dart
│   ├── subject_form_dialog.dart
│   ├── timetable_grid.dart
│   ├── timetable_slot_card.dart
│   └── promotion_student_tile.dart
└── repositories/
    ├── class_repository.dart
    ├── section_repository.dart
    ├── subject_repository.dart
    └── timetable_repository.dart
```

---

## Verification

1. **Class Management**
   - Create all classes (Playgroup to Class 10)
   - Verify display order
   - Check student count accuracy

2. **Section Management**
   - Add sections A, B, C to each class
   - Set capacity limits
   - Deactivate a section

3. **Subject Configuration**
   - Add default subjects
   - Assign to classes
   - Assign teachers

4. **Timetable**
   - Create full timetable for one class
   - Test conflict detection
   - Print timetable

5. **Promotions**
   - Promote students from Class 5 to 6
   - Verify enrollment history
   - Check new roll numbers
