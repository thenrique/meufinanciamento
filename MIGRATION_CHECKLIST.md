# 📋 Migration Application Checklist

**Project:** meufinanciamento  
**Supabase URL:** https://app.supabase.com/project/cpncjeeegxrwbwbdzdwe/sql/new  
**Created:** March 31, 2026

---

## ✅ Pre-Migration Checklist

- [ ] Read `MIGRATION_MANUAL_GUIDE.md` completely
- [ ] Created backup of Supabase database
- [ ] Verified `profiles` table exists
- [ ] Verified `loans` table exists
- [ ] Verified `update_updated_at()` function exists
- [ ] Access to Supabase SQL Editor confirmed
- [ ] Have access to copy/paste (CTRL+C / CTRL+V)

---

## 📝 Migration 002: Create Payment Records Table

### Apply Migration

- [ ] Opened: https://app.supabase.com/project/cpncjeeegxrwbwbdzdwe/sql/new
- [ ] Clicked "New query" button
- [ ] Copied SQL from `MIGRATION_SQL.sql` (lines 1-48) OR `MIGRATION_MANUAL_GUIDE.md` Step 2
- [ ] Pasted all 31 lines of SQL
- [ ] Clicked "Run" button (or Ctrl+Enter)
- [ ] **Saw success message** ✅ (not error)
- [ ] Closed/cleared the query

### Verify Migration 002 Success

Run these queries one by one to verify:

**Query 1: Check table exists**
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_name = 'payment_records' AND table_schema = 'public';
```
- [ ] Result: Shows `payment_records` in `table_name` column

**Query 2: Check columns**
```sql
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'payment_records' ORDER BY ordinal_position;
```
- [ ] Result: Shows columns (id, user_id, loan_id, payment_date, amount_paid, payment_type, notes, created_at, updated_at)

**Query 3: Check indexes**
```sql
SELECT indexname FROM pg_indexes WHERE tablename = 'payment_records';
```
- [ ] Result: Shows 4+ indexes including `idx_unique_payment_per_day`

**Query 4: Check RLS enabled**
```sql
SELECT tablename, rowsecurity FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'payment_records';
```
- [ ] Result: `rowsecurity` should be `true`

**Query 5: Check RLS policy**
```sql
SELECT policyname FROM pg_policies WHERE tablename = 'payment_records';
```
- [ ] Result: Shows `Usuários gerenciam seus registros de pagamento`

**Query 6: Check trigger**
```sql
SELECT trigger_name FROM information_schema.triggers 
WHERE event_object_table = 'payment_records';
```
- [ ] Result: Shows `trg_payment_records_updated_at`

**Migration 002 Status:**
- [ ] ✅ **ALL CHECKS PASSED** - Proceed to Migration 003
- [ ] ❌ **SOME CHECKS FAILED** - Review errors, see troubleshooting in guide

---

## 📝 Migration 003: Add Payment Due Date to Loans

### Apply Migration

- [ ] Opened: https://app.supabase.com/project/cpncjeeegxrwbwbdzdwe/sql/new
- [ ] Clicked "New query" button
- [ ] Copied SQL from `MIGRATION_SQL.sql` (lines 53-57) OR `MIGRATION_MANUAL_GUIDE.md` Step 3
- [ ] Pasted the single ALTER TABLE statement
- [ ] Clicked "Run" button (or Ctrl+Enter)
- [ ] **Saw success message** ✅ (not error)
- [ ] Closed/cleared the query

### Verify Migration 003 Success

Run these queries to verify:

**Query 1: Check column exists**
```sql
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'loans' AND column_name = 'payment_due_date_day';
```
- [ ] Result: Shows column with:
  - `column_name`: payment_due_date_day
  - `data_type`: integer
  - `column_default`: 10 (or nextval)

**Query 2: Verify constraint**
```sql
SELECT constraint_name, constraint_type 
FROM information_schema.table_constraints 
WHERE table_name = 'loans' AND constraint_name LIKE '%payment_due_date%';
```
- [ ] Result: Shows CHECK constraint on payment_due_date_day

**Query 3: Check in loans table structure**
```sql
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'loans' 
ORDER BY ordinal_position DESC LIMIT 5;
```
- [ ] Result: `payment_due_date_day` appears in the list

**Migration 003 Status:**
- [ ] ✅ **ALL CHECKS PASSED** - Migrations complete!
- [ ] ❌ **SOME CHECKS FAILED** - Review errors, see troubleshooting

---

## 🎉 Post-Migration Tasks

### Test API

- [ ] Create test payment record via API
  ```bash
  curl -X POST https://cpncjeeegxrwbwbdzdwe.supabase.co/rest/v1/payment_records \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer YOUR_JWT_TOKEN" \
    -d '{"user_id":"...", "loan_id":"...", "payment_date":"2026-03-31", "amount_paid":100.00, "payment_type":"normal"}'
  ```
  - [ ] Success: Record created

- [ ] Test RLS protection
  - [ ] Create payment as User A
  - [ ] Try to read with User B's token
  - [ ] Verify User B cannot see User A's payments
  - [ ] ✅ RLS working correctly

- [ ] Test trigger
  - [ ] Update a payment_record
  - [ ] Check that `updated_at` changed automatically
  - [ ] ✅ Trigger working correctly

### Update Frontend Code

- [ ] Update components to use `payment_records` table
- [ ] Add UI for `payment_due_date_day` in loan settings
- [ ] Test with sample data
- [ ] Deploy to production

### Database Backup

- [ ] Created backup after successful migrations
  - [ ] Date: _____________
  - [ ] Backup ID: _____________

---

## 📊 Final Summary

| Migration | Status | Date Applied | Time | Notes |
|-----------|--------|--------------|------|-------|
| 002 - Create payment_records | ⬜ Pending | ___/___/___ | ____:____ | |
| 003 - Add payment_due_date_day | ⬜ Pending | ___/___/___ | ____:____ | |

---

## 📞 Support

If you encounter any issues during migration:

1. **Check error message** - Supabase provides specific error messages
2. **Review guide** - See `MIGRATION_MANUAL_GUIDE.md` Troubleshooting section
3. **Verify prerequisites** - All tables and functions must exist
4. **Use rollback** - Drop table/column and try again

**Migration Files:**
- Step-by-step guide: `MIGRATION_MANUAL_GUIDE.md`
- SQL statements: `MIGRATION_SQL.sql`
- Status report: `MIGRATION_RESULTS.md`
- Original migration files: `supabase/migrations/002_*.sql` and `supabase/migrations/003_*.sql`

---

**Migrations Ready for Application!** ✅
