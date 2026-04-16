# Phase 7: Fee Management

## Goals
- Comprehensive fee structure configuration
- Invoice generation (individual and bulk)
- Payment collection with receipt printing
- Concession management
- Defaulter tracking

---

## Tasks

### 7.1 Database Tables

```dart
class FeeTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 50)();
  // tuition, admission, transport, library, lab, sports, etc.
  TextColumn get description => text().nullable()();
  BoolColumn get isMonthly => boolean().withDefault(const Constant(true))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class FeeStructures extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId => integer().references(Classes, #id)();
  IntColumn get feeTypeId => integer().references(FeeTypes, #id)();
  RealColumn get amount => real()();
  TextColumn get academicYear => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text().unique()();
  IntColumn get studentId => integer().references(Students, #id)();
  TextColumn get month => text()(); // e.g., "2026-02"
  RealColumn get totalAmount => real()();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get netAmount => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  TextColumn get status => text()(); // pending, partial, paid, overdue
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class InvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  IntColumn get feeTypeId => integer().references(FeeTypes, #id)();
  RealColumn get amount => real()();
  RealColumn get discount => real().withDefault(const Constant(0))();
}

class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get receiptNumber => text().unique()();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  IntColumn get studentId => integer().references(Students, #id)();
  RealColumn get amount => real()();
  TextColumn get paymentMode => text()(); // cash, bank, cheque, online
  TextColumn get referenceNumber => text().nullable()();
  TextColumn get remarks => text().nullable()();
  IntColumn get receivedBy => integer().references(Users, #id)();
  DateTimeColumn get paymentDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Concessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studentId => integer().references(Students, #id)();
  IntColumn get feeTypeId => integer().nullable().references(FeeTypes, #id)();
  TextColumn get discountType => text()(); // percentage, fixed
  RealColumn get discountValue => real()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
```

---

### 7.2 Fee Structure Screen

**Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ Fee Structure                    Academic Year: [2025-26 ▾]│
├─────────────────────────────────────────────────────────────┤
│ [Fee Types] [Class-wise Fees] [Concessions]                │
├─────────────────────────────────────────────────────────────┤
│ CLASS-WISE FEE STRUCTURE                                   │
├─────────────────────────────────────────────────────────────┤
│           │ Tuition │ Admission │ Transport │ Total        │
├───────────┼─────────┼───────────┼───────────┼──────────────┤
│ Playgroup │  3,000  │   5,000   │   2,000   │  10,000      │
│ Nursery   │  3,500  │   5,000   │   2,000   │  10,500      │
│ KG        │  4,000  │   5,000   │   2,000   │  11,000      │
│ Class 1   │  4,500  │   5,000   │   2,000   │  11,500      │
│ ...       │  ...    │   ...     │   ...     │  ...         │
├─────────────────────────────────────────────────────────────┤
│                              [✏️ Edit Structure]            │
└─────────────────────────────────────────────────────────────┘
```

---

### 7.3 Invoice Generation

**Options:**
1. **Individual Invoice** - For a single student
2. **Bulk Monthly Invoice** - For entire class/school

**Invoice Generation Flow:**
```
┌─────────────────────────────────────────────────────────────┐
│ Generate Monthly Invoices                                   │
├─────────────────────────────────────────────────────────────┤
│ Month: [February 2026 ▾]                                   │
│ Class: [All Classes ▾]    Section: [All Sections ▾]        │
│ Due Date: [📅 15 Feb 2026]                                 │
├─────────────────────────────────────────────────────────────┤
│ Preview:                                                    │
│ • Total Students: 450                                       │
│ • Already Generated: 0                                      │
│ • To Generate: 450                                          │
│ • Total Amount: PKR 2,250,000                              │
├─────────────────────────────────────────────────────────────┤
│                    [Generate Invoices]                      │
└─────────────────────────────────────────────────────────────┘
```

**Invoice Details View:**
```
┌─────────────────────────────────────────────────────────────┐
│ INVOICE #INV-2026-02-0001           Status: PENDING        │
├─────────────────────────────────────────────────────────────┤
│ Student: Ahmed Ali (5A-01)                                  │
│ Class: 5-A                   Month: February 2026           │
│ Due Date: 15 Feb 2026                                       │
├─────────────────────────────────────────────────────────────┤
│ Fee Type           │ Amount   │ Discount  │ Net Amount     │
├────────────────────┼──────────┼───────────┼────────────────┤
│ Tuition Fee        │   5,000  │      0    │     5,000      │
│ Transport Fee      │   2,000  │      0    │     2,000      │
├────────────────────┼──────────┼───────────┼────────────────┤
│ TOTAL              │   7,000  │      0    │     7,000      │
├─────────────────────────────────────────────────────────────┤
│ Paid: 0    │  Balance: 7,000                               │
├─────────────────────────────────────────────────────────────┤
│          [💵 Collect Payment]    [🖨️ Print Invoice]        │
└─────────────────────────────────────────────────────────────┘
```

---

### 7.4 Payment Collection

**Payment Dialog:**
```
┌─────────────────────────────────────────────────────────────┐
│ Collect Payment                                             │
├─────────────────────────────────────────────────────────────┤
│ Invoice: INV-2026-02-0001                                   │
│ Student: Ahmed Ali                                          │
│ Outstanding: PKR 7,000                                      │
├─────────────────────────────────────────────────────────────┤
│ Amount:       [    7,000    ]                              │
│ Payment Mode: [Cash ▾]                                      │
│ Reference:    [____________] (for bank/cheque/online)      │
│ Remarks:      [____________]                                │
├─────────────────────────────────────────────────────────────┤
│           [Cancel]    [💵 Collect & Print Receipt]         │
└─────────────────────────────────────────────────────────────┘
```

**Payment Modes:**
- Cash (no reference needed)
- Bank Transfer (bank ref required)
- Cheque (cheque number required)
- Online (transaction ID required)

---

### 7.5 Receipt Generation

**Receipt Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│                      [SCHOOL LOGO]                          │
│                    Al Madina School                         │
│                    PAYMENT RECEIPT                          │
├─────────────────────────────────────────────────────────────┤
│ Receipt No: RCP-2026-02-0001       Date: 03 Feb 2026       │
│ Invoice No: INV-2026-02-0001                               │
├─────────────────────────────────────────────────────────────┤
│ Student Name: Ahmed Ali                                     │
│ Father Name: Ali Khan                                       │
│ Class: 5-A                         Roll No: 5A-01          │
├─────────────────────────────────────────────────────────────┤
│ Fee Month: February 2026                                    │
├─────────────────────────────────────────────────────────────┤
│ Fee Type           │ Amount                                 │
├────────────────────┼────────────────────────────────────────┤
│ Tuition Fee        │                               5,000   │
│ Transport Fee      │                               2,000   │
├────────────────────┼────────────────────────────────────────┤
│ Total              │                               7,000   │
├────────────────────┼────────────────────────────────────────┤
│ Amount Paid        │                               7,000   │
│ Payment Mode       │                                 Cash   │
├─────────────────────────────────────────────────────────────┤
│ Amount in Words: Seven Thousand Rupees Only                 │
├─────────────────────────────────────────────────────────────┤
│ Received By: Admin User            Signature: ____________ │
│                                                             │
│ Note: This is a computer generated receipt                  │
└─────────────────────────────────────────────────────────────┘
```

---

### 7.6 Defaulter Tracking

**Defaulter List Screen:**
```
┌─────────────────────────────────────────────────────────────┐
│ Fee Defaulters                       As of: 03 Feb 2026    │
├─────────────────────────────────────────────────────────────┤
│ Filter: [All Classes ▾] [Days Overdue: 30+ ▾]              │
├─────────────────────────────────────────────────────────────┤
│  # │ Student      │ Class │ Pending │ Months      │ Days  │
├────┼──────────────┼───────┼─────────┼─────────────┼───────┤
│  1 │ Usman Raza   │ 5-A   │  14,000 │ Jan, Feb    │  35   │
│  2 │ Sara Malik   │ 3-B   │   7,000 │ Feb         │  20   │
│  3 │ Hassan Khan  │ 7-A   │  21,000 │ Dec, Jan, Feb│ 65   │
├─────────────────────────────────────────────────────────────┤
│ Total Defaulters: 15           Total Outstanding: 185,000  │
├─────────────────────────────────────────────────────────────┤
│              [📄 Export List]    [🖨️ Print Notices]        │
└─────────────────────────────────────────────────────────────┘
```

---

### 7.7 Fee Reports

1. **Collection Summary**
   - Daily/monthly collection totals
   - Payment mode breakdown
   - Class-wise collection

2. **Outstanding Report**
   - Total pending fees
   - Age-wise analysis
   - Student-wise breakdown

3. **Concession Report**
   - Students with concessions
   - Total discount given

---

## Files Structure

```
lib/features/fees/
├── screens/
│   ├── fees_screen.dart
│   ├── fee_structure_screen.dart
│   ├── invoice_list_screen.dart
│   ├── invoice_generate_screen.dart
│   ├── payment_collection_screen.dart
│   ├── defaulter_list_screen.dart
│   └── fee_reports_screen.dart
├── controllers/
│   ├── fee_structure_controller.dart
│   ├── invoice_controller.dart
│   └── payment_controller.dart
├── widgets/
│   ├── invoice_card.dart
│   ├── payment_dialog.dart
│   ├── receipt_template.dart
│   └── defaulter_tile.dart
├── services/
│   ├── invoice_service.dart
│   └── receipt_service.dart
└── repositories/
    ├── fee_repository.dart
    └── payment_repository.dart
```

---

## Verification

1. **Fee Structure**
   - Define fee types
   - Set class-wise amounts
   - Verify totals

2. **Invoice Generation**
   - Generate for single student
   - Generate bulk for class
   - Check concession application

3. **Payment Collection**
   - Collect cash payment
   - Print receipt
   - Verify invoice status update

4. **Defaulter Tracking**
   - View defaulter list
   - Filter by days overdue
   - Export list

5. **Reports**
   - Generate collection summary
   - Check outstanding report
   - Verify amounts match
