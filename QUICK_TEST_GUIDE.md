# 🧪 Quick Test Guide - Verify All Fixes

## Step 1: Restart the Main App (Server)
```bash
# Stop and restart the Flutter app
flutter run
```

## Step 2: Test Debug Endpoints

Open browser and go to these URLs:

### Check Academic Year
```
http://192.168.1.XXX:8181/api/v1/debug/academic-year
```
**Expected:** Shows current academic year (e.g., "2025-2026")

### Check Class Data
```
http://192.168.1.XXX:8181/api/v1/debug/class/2/3
```
**Expected:** Shows enrollments, students, and their statuses

## Step 3: Check Server Logs

Look for these messages in the console:
```
[SyncServer] GetStudents for class 2-3: 0 students in Xms
[SyncServer] Empty class diagnostics: {...}
```

## Step 4: Test Teacher App

1. **Logout** from teacher app
2. **Login** again
3. **Open** class 2-3
4. **Check** error message

### Expected Results:

#### If students exist and everything works:
- Students list appears ✅

#### If 0 students but data exists:
You should see a **detailed error message** like:
```
No students found. Server diagnostics:

• Enrollments exist for years: 2025-2025
  But current year is: 2025-2026
  Please update academic year in main system settings.

Suggested fix: Enrollments exist for years [2025-2025] but 
current year is 2025-2026. Update enrollments or academic year.
```

## Step 5: Fix Data Issues (If Needed)

### If Academic Year Mismatch:
```sql
-- Run in SQLite database browser
UPDATE enrollments 
SET academic_year = '2025-2026'  -- Use your actual year
WHERE class_id = 2 AND section_id = 3;
```

### If isCurrent is False:
```sql
UPDATE enrollments 
SET is_current = 1
WHERE class_id = 2 AND section_id = 3;
```

### If Student Status Not Active:
```sql
UPDATE students 
SET status = 'active'
WHERE id IN (SELECT student_id FROM enrollments WHERE class_id = 2 AND section_id = 3);
```

## Step 6: Regenerate Freezed Models (If Build Errors)

```bash
cd edux_teacher_app
flutter pub run build_runner build --delete-conflicting-outputs
```

## Common Issues & Solutions

### Issue: "No active academic year"
**Fix:** Go to Main App → Settings → Academic Settings → Set Current Academic Year

### Issue: "No students found" even after SQL fixes
**Fix:** Check that `staff_subject_assignments` has the teacher assigned to class/section

### Issue: "Server not configured" in teacher app
**Fix:** Re-enter server IP in teacher app login screen

## Verification Checklist

- [ ] Debug endpoint `/api/v1/debug/academic-year` returns data
- [ ] Debug endpoint `/api/v1/debug/class/2/3` returns enrollments
- [ ] Server logs show diagnostic information
- [ ] Teacher app shows helpful error messages (not just "0 students")
- [ ] Case-insensitive status check working (students with "Active" status appear)
- [ ] Academic year from server is used (not locally generated)

---

**If you still see issues, share the server log output with the diagnostic information!**
