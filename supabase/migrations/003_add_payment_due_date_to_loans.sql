-- Adicionar coluna de dia de vencimento do pagamento à tabela loans
ALTER TABLE loans ADD COLUMN payment_due_date_day INTEGER DEFAULT 10 CHECK (payment_due_date_day >= 1 AND payment_due_date_day <= 31);
