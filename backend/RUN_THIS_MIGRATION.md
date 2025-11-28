# 🚨 URGENT: Run This Migration

## The Error
```
Server error - Please try again later
```

**Cause:** The database doesn't have the location columns yet!

---

## ✅ Fix: Run Migration

### Option 1: Using psql (Recommended)

```bash
# Connect to your database
psql -U postgres -d financial_db_232143

# Run the migration
\i migrations/add_location_fields.sql

# Exit
\q
```

### Option 2: Using pgAdmin
1. Open pgAdmin
2. Connect to `financial_db_232143`
3. Open Query Tool
4. Copy contents of `migrations/add_location_fields.sql`
5. Paste and Execute

### Option 3: Using Python script

```bash
cd backend
python migrations/run_migration.py
```

---

## What This Does

Adds 3 new columns to `transactions_232143` table:
- `location_name_232143` (TEXT)
- `latitude_232143` (DECIMAL)
- `longitude_232143` (DECIMAL)

---

## After Running Migration

1. Migration will show: "Location fields migration completed successfully!"
2. Restart backend (if not auto-restarted)
3. Add a transaction in the app
4. Location will now save! ✅

---

## Verify It Worked

After migration, check the table structure:

```sql
\d transactions_232143
```

You should see the 3 new location columns!

🎯 **RUN THE MIGRATION NOW!**
