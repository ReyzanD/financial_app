# 🐘 PostgreSQL Migration & Deployment Guide

## Step 1: Install PostgreSQL Locally (Optional - for testing)

### Windows:
1. Download PostgreSQL from https://www.postgresql.org/download/windows/
2. Install with default settings
3. Remember the password you set for the `postgres` user

### Verify Installation:
```bash
psql --version
```

---

## Step 2: Export Your Current MySQL Data

```bash
cd backend
python migrate_to_postgresql.py
```

This will create a `mysql_export/` folder with all your data in JSON format.

---

## Step 3A: Local PostgreSQL Setup (Testing)

### Create Database:
```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE financial_db_232143;

# Exit
\q
```

### Run Schema:
```bash
psql -U postgres -d financial_db_232143 -f postgresql_schema.sql
```

### Import Data:
```bash
python import_to_postgresql.py
```

### Create .env file:
```bash
cp .env.example .env
```

Edit `.env`:
```
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=your_postgres_password
DB_NAME=financial_db_232143
DB_PORT=5432
JWT_SECRET_KEY=your-secret-key-here
DEBUG=True
```

### Test Locally:
```bash
pip install -r requirements.txt
python app.py
```

---

## Step 3B: Deploy to Render (Production - FREE)

### 1. Create Render Account
- Go to https://render.com
- Sign up with GitHub

### 2. Create PostgreSQL Database
1. Click "New +" → "PostgreSQL"
2. Name: `financial-db`
3. Database: `financial_db_232143`
4. User: (auto-generated)
5. Region: Singapore (closest to Indonesia)
6. Plan: **Free**
7. Click "Create Database"
8. Wait 2-3 minutes for provisioning
9. **Copy the "Internal Database URL"** (looks like: `postgresql://user:pass@host/db`)

### 3. Deploy Flask Backend
1. Push your code to GitHub
2. Go to Render Dashboard
3. Click "New +" → "Web Service"
4. Connect your GitHub repository
5. Configure:
   - **Name**: `financial-app-backend`
   - **Region**: Singapore
   - **Branch**: main
   - **Root Directory**: `backend` (if your backend is in a subdirectory)
   - **Runtime**: Python 3
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn app:app`
   - **Plan**: Free

### 4. Set Environment Variables
In Render web service settings, add:

```
DATABASE_URL = [paste your Internal Database URL from step 2]
JWT_SECRET_KEY = [generate a random secure string]
DEBUG = False
```

### 5. Import Data to Production Database

#### Option A: From your computer
```bash
# Set DATABASE_URL environment variable
export DATABASE_URL="your_render_database_url_here"

# Run import script
python import_to_postgresql.py
```

#### Option B: Using Render Shell (after deployment)
1. Go to your web service in Render
2. Click "Shell" tab
3. Upload `mysql_export/` folder
4. Run: `python import_to_postgresql.py`

### 6. Get Your API URL
After deployment, Render will give you a URL like:
```
https://financial-app-backend.onrender.com
```

---

## Step 4: Update Flutter App

Update your Flutter app's API base URL:

```dart
// lib/services/api_service.dart
final String baseUrl = 'https://financial-app-backend.onrender.com/api/v1';
```

---

## 🎉 You're Live!

Your app is now running on free hosting!

### Important Notes:

1. **Free Tier Limitations:**
   - App spins down after 15 minutes of inactivity
   - First request after spin-down takes 30-60 seconds
   - 750 hours/month free (enough for hobby use)

2. **Database Backups:**
   - Render Free PostgreSQL includes automatic backups
   - 7-day retention

3. **Monitoring:**
   - Check Render dashboard for logs
   - Monitor database usage

4. **Upgrading:**
   - If you need 24/7 uptime later, upgrade to Render Starter ($7/month)

---

## Troubleshooting

### "Connection Refused" Error
- Check if DATABASE_URL is set correctly
- Verify PostgreSQL service is running

### "Module Not Found" Error
```bash
pip install -r requirements.txt
```

### Migration Issues
- Make sure MySQL server is running before export
- Check if export files exist in `mysql_export/` folder

### Render Deployment Failed
- Check build logs in Render dashboard
- Verify `requirements.txt` has all dependencies
- Ensure `gunicorn` is in requirements.txt

---

## Cost Comparison

| Service | Flask Backend | PostgreSQL DB | Total/Month |
|---------|--------------|---------------|-------------|
| Render Free | $0 | $0 | **$0** |
| Render Starter | $7 | $7 | $14 |
| Railway Free | $5 credit | Included | **$0** |

**Recommendation**: Start with Render Free, upgrade only if needed!

---

## Need Help?

- Render Docs: https://render.com/docs
- PostgreSQL Docs: https://www.postgresql.org/docs/
- Create an issue on your GitHub repo

---

## Next Steps After Deployment

1. ✅ Test all API endpoints
2. ✅ Create a new user account
3. ✅ Add sample transactions
4. ✅ Verify location recommendations work
5. ✅ Share your app with friends! 🎉
