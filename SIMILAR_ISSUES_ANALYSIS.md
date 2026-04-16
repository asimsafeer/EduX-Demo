# Similar Issues Analysis - EduX Codebase

**Date:** 2026-03-03  
**Scope:** Full codebase analysis for patterns similar to Payment Collection issues

---

## 🔴 Critical Issues Found

### **Issue 1: Duplicate Payment Mode Switch Statements (Code Duplication)**

**Problem:** Payment mode icon and color switch statements are duplicated across 6+ files instead of using the centralized `PaymentModeHelper`.

**Files Affected:**
1. `lib/screens/fees/fee_reports_screen.dart` (4 duplicate functions - lines 276-304, 782-810)
2. `lib/screens/fees/fee_dashboard_screen.dart` (lines 204-220)
3. `lib/screens/fees/payment_details_screen.dart` (lines 290-306)
4. `lib/screens/fees/payments_list_screen.dart` (lines 486-514)
5. `lib/screens/fees/payment_collection_screen.dart` (has its own version)

**Recommended Fix:**
Replace all duplicate switch statements with the centralized helper:
```dart
// INSTEAD OF:
IconData _getPaymentModeIcon(String mode) {
  switch (mode) {
    case 'cash': return Icons.money;
    case 'bank_transfer': return Icons.account_balance;
    // ...
  }
}

// USE:
import '../../core/widgets/payment_mode_helpers.dart';
// ...
Icon(mode.paymentModeIcon)
Text(mode.paymentModeDisplayName)
```

---

### **Issue 2: Duplicate Status Color/Icon Functions**

**Problem:** Status color and icon helpers are duplicated across multiple screens instead of using centralized constants.

**Files Affected:**
1. `lib/screens/fees/payment_collection_screen.dart` - `_getStatusColor`, `_getStatusIcon` (lines 783-810)
2. `lib/screens/fees/invoices_list_screen.dart` - `_getStatusColor`, `_getStatusIcon` (lines 34-58)
3. `lib/screens/students/widgets/student_card.dart` - `_getStatusColor` (lines 283-295)
4. `lib/screens/exams/exams_screen.dart` - `_getStatusColor` (lines 156-166)
5. `lib/screens/attendance/widgets/attendance_student_row.dart` - `_getStatusColor` (lines 183-193)
6. `lib/screens/attendance/attendance_report_screen.dart` - `_getStatusColor` (lines 430-445)

**Recommended Fix:**
Create a centralized `StatusHelpers` class in `lib/core/extensions/status_extensions.dart` similar to `PaymentModeHelper`.

---

### **Issue 3: Hardcoded Status Strings**

**Problem:** Status strings like 'paid', 'pending', 'active' are hardcoded instead of using constants.

**Files Affected:**
1. `lib/services/payroll_service.dart` (lines 105, 196) - `status == 'paid'`
2. `lib/services/invoice_service.dart` (lines 965, 1002) - `status == 'paid'`
3. `lib/services/invoice_export_service.dart` (lines 534-536) - status color checks
4. `lib/screens/students/widgets/student_card.dart` (line 365) - `status == 'active'`
5. `lib/screens/staff/staff_profile_screen.dart` (lines 663-679) - multiple `status == 'paid'`
6. `lib/screens/staff/staff_payroll_screen.dart` (line 324) - `status == 'paid'`
7. `lib/screens/fees/widgets/invoice_card.dart` (line 192) - `status == 'paid'`
8. `lib/screens/fees/invoice_details_screen.dart` (line 419) - `status == 'paid'`
9. `lib/screens/exams/widgets/exam_card.dart` (line 171) - `status == 'active'`
10. `lib/screens/exams/exams_screen.dart` (lines 405, 413) - `status == 'active'`
11. `lib/screens/exams/marks_entry_screen.dart` (line 98) - `status == 'active'`
12. `lib/repositories/payment_repository.dart` (line 629) - `status == 'paid'`
13. `lib/repositories/payroll_repository.dart` (line 248) - `status == 'pending'`
14. `lib/repositories/leave_repository.dart` (line 23) - `status == 'pending'`
15. `lib/repositories/invoice_repository.dart` (line 35) - `status == 'paid'`

**Recommended Fix:**
Replace with constants:
```dart
// INSTEAD OF:
if (status == 'paid') { ... }

// USE:
if (status == FeeConstants.invoiceStatusPaid) { ... }
if (status == StudentConstants.statusActive) { ... }
```

---

### **Issue 4: Potential Provider Cache Issues in Other Screens**

**Problem:** Similar pattern to payment collection - screens with selection changes may not invalidate providers properly.

**Files to Review:**
1. `lib/screens/staff/staff_assignments_screen.dart`
   - Staff selection changes (lines 369, 395, 453)
   - Should invalidate related providers

2. `lib/screens/attendance/attendance_report_screen.dart`
   - Class/Section/Student changes (lines 303, 304, 329, 344)
   - Should invalidate report data providers

3. `lib/screens/students/student_promotion_screen.dart`
   - Class/Section selection (lines 204, 228)
   - Uses `.autoDispose` on providers (GOOD PRACTICE)

4. `lib/screens/exams/exam_form_screen.dart`
   - Subject selection (lines 1135)
   - Should verify provider invalidation

5. `lib/screens/academics/timetable_screen.dart`
   - Class section selection (line 115)
   - Should invalidate timetable provider

6. `lib/screens/academics/class_subject_assignment_screen.dart`
   - Teacher selection (line 230)
   - Should verify provider invalidation

---

### **Issue 5: Missing State Clearing in StateNotifiers**

**Problem:** Similar to `setStudentId`, other StateNotifiers may not clear errors when setting new values.

**Files to Review:**
1. `lib/providers/fee_provider.dart`
   - `InvoiceGenerationNotifier.setClassId()` - clears section (GOOD)
   - `GenericInvoiceGenerationNotifier.setStudentId()` - should verify error clearing

2. `lib/providers/attendance_provider.dart` (NEEDS REVIEW)
   - Check if error clearing is consistent

3. `lib/providers/staff_provider.dart` (NEEDS REVIEW)
   - Check if error clearing is consistent

---

## 🟡 Medium Priority Issues

### **Issue 6: Hardcoded Currency Formatting**

**Problem:** Currency formatting is still duplicated in many places.

**Files with Hardcoded Currency:**
1. `lib/screens/fees/fee_reports_screen.dart` (lines 82-86, 361-364, 557-560, 668-671)
2. `lib/screens/fees/payment_collection_screen.dart` (lines 31-35)
3. `lib/screens/fees/payments_list_screen.dart` (lines 25-29)
4. `lib/screens/fees/invoices_list_screen.dart` (lines 28-32)

**Recommended Fix:**
Use the centralized `CurrencyFormatter`:
```dart
// INSTEAD OF:
final _currencyFormat = NumberFormat.currency(
  locale: 'en_PK',
  symbol: 'Rs. ',
  decimalDigits: 0,
);

// USE:
import '../../core/extensions/currency_extensions.dart';
// ...
amount.toCurrency()  // Extension method
```

---

### **Issue 7: Date Range Handling Inconsistencies**

**Problem:** Similar to the payment collection calendar filter, other date-based filters may have edge cases.

**Files to Review:**
1. `lib/screens/fees/fee_reports_screen.dart`
   - Daily collection tab uses `setState(() => _selectedDate = date)` (line 102)
   - Provider watches `dailyCollectionProvider(_selectedDate)` - should work correctly

2. `lib/screens/attendance/attendance_report_screen.dart`
   - Date changes may need provider invalidation

---

## ✅ Good Practices Found

### **Proper Provider Invalidation Examples:**

1. `lib/screens/students/student_list_screen.dart` (lines 77-79):
```dart
ref.invalidate(studentsProvider);
ref.invalidate(studentCountProvider);
ref.invalidate(allStudentsProvider);
```

2. `lib/screens/staff/staff_payroll_screen.dart` (lines 436-437):
```dart
ref.invalidate(payrollForMonthProvider);
ref.invalidate(payrollSummaryProvider);
```

3. `lib/screens/staff/staff_leave_screen.dart` (lines 75-76):
```dart
ref.invalidate(pendingLeaveRequestsProvider);
ref.invalidate(leaveRequestsProvider);
```

4. `lib/screens/students/student_promotion_screen.dart` (line 707):
```dart
ref.invalidate(_studentsForPromotionProvider);
```

---

## 📋 Recommended Action Plan

### Phase 1: Critical Fixes (High Priority)
1. ✅ Fix Payment Collection Screen (COMPLETED)
2. ✅ Fix Payments List Screen (COMPLETED)
3. Fix hardcoded status strings in service files
4. Fix hardcoded status strings in repository files

### Phase 2: Code Quality Improvements (Medium Priority)
5. Replace duplicate payment mode switch statements with centralized helper
6. Create centralized status color/icon helpers
7. Replace hardcoded currency formatters with centralized extension

### Phase 3: Provider Cache Review (Low Priority)
8. Review and fix provider invalidation in:
   - Staff assignments screen
   - Attendance report screen
   - Exam form screen
   - Timetable screen

---

## 🛠️ Quick Fixes Available

### Fix: Replace Payment Mode Switch Statements

Create a single import and replace all instances:

```dart
// Add to lib/core/widgets/payment_mode_helpers.dart if not exists:
extension PaymentModeString on String {
  IconData get icon {
    switch (this) {
      case 'cash': return Icons.money;
      case 'bank_transfer': return Icons.account_balance;
      case 'cheque': return Icons.article;
      case 'online': return Icons.phone_android;
      default: return Icons.payment;
    }
  }
  
  Color get color {
    switch (this) {
      case 'cash': return Colors.green;
      case 'bank_transfer': return Colors.blue;
      case 'cheque': return Colors.orange;
      case 'online': return Colors.purple;
      default: return Colors.grey;
    }
  }
}
```

Then replace all `_getPaymentModeIcon` and `_getPaymentModeColor` functions with:
```dart
Icon(paymentMode.icon)
Text(paymentMode.displayName)  // If available
```

---

## 📊 Issue Summary

| Category | Count | Priority |
|----------|-------|----------|
| Hardcoded status strings | 15+ files | 🔴 Critical |
| Duplicate payment mode helpers | 6 files | 🟡 Medium |
| Duplicate status helpers | 6 files | 🟡 Medium |
| Hardcoded currency format | 4 files | 🟡 Medium |
| Potential provider cache issues | 6 files | 🟢 Low |

---

*Analysis completed by: Kimi Code CLI*  
*Date: 2026-03-03*
