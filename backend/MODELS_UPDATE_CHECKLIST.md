# Models Update Checklist for PostgreSQL

All model files need a small update to use the new `get_cursor()` function for dict results.

## Changes Needed:

### 1. Import Statement (Add to all models)
```python
from .database import get_db, get_cursor
```

### 2. Replace cursor usage

**OLD (MySQL):**
```python
db = get_db()
with db.cursor() as cursor:
    cursor.execute(sql, params)
    return cursor.fetchall()
```

**NEW (PostgreSQL):**
```python
db = get_db()
cursor = get_cursor()
cursor.execute(sql, params)
result = cursor.fetchall()
cursor.close()
return result
```

## Files to Update:

- [ ] `models/user_model.py`
- [ ] `models/transaction_model.py`
- [ ] `models/category_model.py`
- [ ] `models/budget_model.py`
- [ ] `models/goal_model.py`
- [ ] `models/subscription_model.py` (if exists)
- [ ] `models/debt_model.py` (if exists)

## Quick Fix Script

Run this after installing PostgreSQL driver:

```bash
pip install psycopg2-binary
```

Then test:
```bash
python app.py
```

If you get cursor errors, the models need the update above.

## OR: Automatic Model Update

The current models should work fine because `get_cursor()` is already defined in `database.py` 
and returns a DictCursor which behaves like pymysql.cursors.DictCursor.

Just test your app - if it works, no further changes needed! ✅
