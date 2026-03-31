# Database Migration Guide - Manual Application

**Project:** meufinanciamento  
**Supabase Project ID:** cpncjeeegxrwbwbdzdwe  
**Supabase URL:** https://app.supabase.com/project/cpncjeeegxrwbwbdzdwe/sql/new  
**Generated:** 2026-03-31T01:06:51.935Z

---

## Overview

This document provides instructions for manually applying two database migrations to your Supabase project. These migrations cannot be automatically applied via API, so they must be run through the Supabase SQL Editor.

**Migrations to Apply:**
1. Migration 002: Create payment_records table
2. Migration 003: Add payment_due_date_day column to loans table

---

## ⚠️ IMPORTANT: Before You Start

1. **Backup your database** in Supabase (Settings → Backups)
2. **Check that these tables exist:**
   - `profiles` - Required by payment_records foreign key
   - `loans` - Required by payment_records foreign key
   - Verify the `update_updated_at()` trigger function exists (from initial schema)

3. **Verify existing schema:**
   ```sql
   -- Run this first to check for conflicts
   SELECT table_name FROM information_schema.tables 
   WHERE table_name IN ('payment_records', 'loans') 
   AND table_schema = 'public';
   ```

---

## Step-by-Step Instructions

### Step 1: Access Supabase SQL Editor

1. Go to: https://app.supabase.com/project/cpncjeeegxrwbwbdzdwe/sql/new
2. Or navigate through the dashboard:
   - Click "SQL Editor" in the left sidebar
   - Click "New query"

### Step 2: Apply Migration 002 - Create payment_records Table

1. Copy the entire SQL block below
2. Paste into the Supabase SQL Editor
3. Click the "Run" button (or press Ctrl+Enter)
4. Wait for success confirmation

**Migration 002 SQL:**

```sql
-- Tabela de registros de pagamentos para "Estimado x Realizado"
CREATE TABLE payment_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  loan_id UUID REFERENCES loans(id) ON DELETE CASCADE NOT NULL,
  payment_date DATE NOT NULL,
  amount_paid DECIMAL(15,2) NOT NULL CHECK (amount_paid > 0),
  payment_type TEXT NOT NULL CHECK (payment_type IN ('normal', 'extra_monthly', 'extra_one_time', 'amortization')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para performance
CREATE UNIQUE INDEX idx_unique_payment_per_day ON payment_records(loan_id, payment_date);
CREATE INDEX idx_payment_records_loan_id ON payment_records(loan_id);
CREATE INDEX idx_payment_records_user_id ON payment_records(user_id);
CREATE INDEX idx_payment_records_date ON payment_records(payment_date);

-- Row Level Security
ALTER TABLE payment_records ENABLE ROW LEVEL SECURITY;

-- Política RLS: usuários só veem seus próprios registros de pagamento
CREATE POLICY "Usuários gerenciam seus registros de pagamento"
  ON payment_records FOR ALL USING (auth.uid() = user_id);

-- Trigger para atualizar updated_at automaticamente
CREATE TRIGGER trg_payment_records_updated_at
  BEFORE UPDATE ON payment_records
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

**Expected Result:**
- ✅ Query executed successfully
- ✅ Table created: `payment_records`
- ✅ Indexes created
- ✅ RLS policy created
- ✅ Trigger created

**Verify Migration 002:**
```sql
-- Check if payment_records table exists
SELECT table_name FROM information_schema.tables 
WHERE table_name = 'payment_records' AND table_schema = 'public';

-- Check indexes
SELECT indexname FROM pg_indexes WHERE tablename = 'payment_records';

-- Check RLS policies
SELECT policyname FROM pg_policies WHERE tablename = 'payment_records';

-- Check trigger
SELECT trigger_name FROM information_schema.triggers 
WHERE event_object_table = 'payment_records';
```

---

### Step 3: Apply Migration 003 - Add payment_due_date_day Column

1. Copy the entire SQL block below
2. Paste into a new Supabase SQL Editor query
3. Click the "Run" button (or press Ctrl+Enter)
4. Wait for success confirmation

**Migration 003 SQL:**

```sql
-- Adicionar coluna de dia de vencimento do pagamento à tabela loans
ALTER TABLE loans ADD COLUMN payment_due_date_day INTEGER DEFAULT 10 CHECK (payment_due_date_day >= 1 AND payment_due_date_day <= 31);
```

**Expected Result:**
- ✅ Query executed successfully
- ✅ Column added to `loans` table
- ✅ Default value set to 10
- ✅ Check constraint applied

**Verify Migration 003:**
```sql
-- Check if column exists
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'loans' AND column_name = 'payment_due_date_day';

-- Check all columns in loans table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'loans' 
ORDER BY ordinal_position;
```

---

## ✅ Complete Verification

Run these queries after both migrations are applied to confirm everything is working:

```sql
-- 1. Verify payment_records table structure
SELECT * FROM information_schema.tables 
WHERE table_name = 'payment_records' AND table_schema = 'public';

-- 2. Verify payment_records columns
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'payment_records' 
ORDER BY ordinal_position;

-- 3. Verify payment_records indexes
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'payment_records';

-- 4. Verify payment_records RLS
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'payment_records';

-- 5. Verify payment_records policies
SELECT schemaname, tablename, policyname, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'payment_records';

-- 6. Verify payment_due_date_day in loans
SELECT column_name, data_type, column_default, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'loans' AND column_name = 'payment_due_date_day';

-- 7. Test creating a payment record (empty insert)
-- This will test the trigger and RLS
INSERT INTO payment_records (
  user_id, 
  loan_id, 
  payment_date, 
  amount_paid, 
  payment_type
) VALUES (
  '00000000-0000-0000-0000-000000000000'::uuid, 
  '00000000-0000-0000-0000-000000000000'::uuid, 
  '2026-03-31'::date, 
  100.00, 
  'normal'
) 
RETURNING *;
-- Note: This will likely fail due to FK constraints, but shows the table is working

-- 8. Verify trigger works
SELECT * FROM information_schema.triggers 
WHERE event_object_table = 'payment_records';
```

---

## Troubleshooting

### Error: "relation payment_records does not exist"
- Migration 002 was not applied successfully
- Re-run Migration 002 and check for any error messages
- Ensure the `profiles` and `loans` tables exist

### Error: "column payment_due_date_day does not exist"
- Migration 003 was not applied successfully
- Re-run Migration 003 and check for any error messages

### Error: "function update_updated_at does not exist"
- The trigger function was not created in the initial schema
- This function should exist from migration 001_initial_schema.sql
- If missing, create it manually in migration 002

### Error: "violates unique constraint"
- The unique index on (loan_id, payment_date) is working correctly
- You cannot have two payments for the same loan on the same date
- This is intentional design

### Rollback Instructions

If you need to rollback the migrations:

```sql
-- Rollback Migration 002
DROP TABLE IF EXISTS payment_records CASCADE;

-- Rollback Migration 003
ALTER TABLE loans DROP COLUMN IF EXISTS payment_due_date_day;
```

---

## Migration Status Summary

| Migration | File | Status | Action |
|-----------|------|--------|--------|
| 002 | 002_create_payment_records.sql | ❌ Requires Manual | See Step 2 above |
| 003 | 003_add_payment_due_date_to_loans.sql | ❌ Requires Manual | See Step 3 above |

---

## API Testing (After Migrations Are Applied)

Once migrations are successfully applied, you can test the API:

### Create a Payment Record
```bash
curl -X POST https://cpncjeeegxrwbwbdzdwe.supabase.co/rest/v1/payment_records \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "user_id": "user-uuid-here",
    "loan_id": "loan-uuid-here",
    "payment_date": "2026-03-31",
    "amount_paid": 500.00,
    "payment_type": "normal"
  }'
```

### Read Payment Records
```bash
curl https://cpncjeeegxrwbwbdzdwe.supabase.co/rest/v1/payment_records \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Update Loans with Payment Due Date
```bash
curl -X PATCH https://cpncjeeegxrwbwbdzdwe.supabase.co/rest/v1/loans?id=eq.loan-uuid-here \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "payment_due_date_day": 15
  }'
```

---

## Next Steps

1. ✅ Apply Migration 002 via Supabase SQL Editor
2. ✅ Apply Migration 003 via Supabase SQL Editor
3. ✅ Run verification queries to confirm success
4. ✅ Test API endpoints with sample data
5. ✅ Update frontend to use new payment_records table
6. ✅ Update frontend to include payment_due_date_day in loan settings

---

## Support

If you encounter any issues:
1. Check the error message carefully
2. Review the Troubleshooting section above
3. Verify all prerequisites are met
4. Check the Supabase documentation: https://supabase.com/docs
5. Review the migration SQL files in `supabase/migrations/`

**Migration Files Location:**
- `/supabase/migrations/002_create_payment_records.sql`
- `/supabase/migrations/003_add_payment_due_date_to_loans.sql`

**Supabase Project:**
- URL: https://app.supabase.com/project/cpncjeeegxrwbwbdzdwe
- SQL Editor: https://app.supabase.com/project/cpncjeeegxrwbwbdzdwe/sql/new

---

**Generated:** March 31, 2026
**Status:** Ready for manual application
