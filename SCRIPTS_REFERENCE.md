# Job Automation Scripts Reference

All the scripts you need to run, monitor, and manage your improved job automation bot.

---

## 🚀 Running the Bot

### **Windows**
```batch
RUN_JOB_BOT.bat
```
Double-click this file or run from Command Prompt.

### **Linux/Mac**
```bash
./RUN_JOB_BOT.sh
```

### **Manual Python Command**
```bash
cd jobautomation
python job_apply_all_platforms.py
```

---

## 📊 Monitoring

### **View Live Logs**
```bash
# Windows
type jobautomation\logs\job_automation_all_platforms.log

# Linux/Mac
tail -f jobautomation/logs/job_automation_all_platforms.log
```

### **View Statistics**
```bash
python VIEW_STATS.py
```

**Output:**
```
======================================================================
 JOB AUTOMATION STATISTICS
======================================================================

Total Applications: 15

By Platform:
  Dice.com: 15

By Status:
  visited: 15

Most Recent Applications:
  Dice.com: DevOps Engineer in Arizona
    Time: 2025-11-07T02:27:41.580000

Total Sessions: 1
======================================================================
```

### **Check Database Directly**
```bash
# Using Python
python -c "
import sqlite3
conn = sqlite3.connect('jobautomation/logs/job_applications.db')
cursor = conn.cursor()
cursor.execute('SELECT * FROM applications LIMIT 10')
for row in cursor.fetchall():
    print(row)
"
```

### **View Screenshots**
```bash
# Windows
dir jobautomation\screenshots

# Linux/Mac
ls -lh jobautomation/screenshots/
```

---

## 🛑 Stopping the Bot

### **Windows**
```batch
# Find and kill the process
tasklist | findstr python
taskkill /F /PID <process_id>
```

### **Linux/Mac**
```bash
./STOP_BOT.sh
```

Or manually:
```bash
pkill -f "python job_apply_all_platforms.py"
```

---

## 🔧 Configuration

### **Edit Settings**
```bash
# Personal info and credentials
nano jobautomation/.env

# Job preferences and platforms
nano jobautomation/config/config.json
```

### **Key Configuration Files**

#### **`.env`** - Credentials (Never commit!)
```bash
PERSONAL_NAME=Your Name
PERSONAL_EMAIL=your.email@gmail.com
PERSONAL_PHONE=+1-555-123-4567
LINKEDIN_EMAIL=your.linkedin@email.com
LINKEDIN_PASSWORD=your_password
RESUME_PATH=resumes/Your_Resume.pdf
SALARY_MIN=80000
MAX_APPLICATIONS_PER_RUN=25
DELAY_BETWEEN_APPLICATIONS=10
HEADLESS_BROWSER=false
SAVE_SCREENSHOTS=true
```

#### **`config.json`** - Job Preferences
```json
{
  "job_preferences": {
    "job_titles": [
      "DevOps Engineer",
      "Cloud Engineer",
      "Site Reliability Engineer"
    ],
    "locations": [
      "Remote",
      "Hybrid",
      "Atlanta, GA"
    ]
  },
  "platforms": {
    "dice": true,
    "linkedin": false,
    "indeed": false
  }
}
```

---

## 📂 File Structure

```
email-automation/
├── RUN_JOB_BOT.bat          ← Windows launcher
├── RUN_JOB_BOT.sh           ← Linux/Mac launcher
├── STOP_BOT.sh              ← Stop script
├── VIEW_STATS.py            ← Statistics viewer
├── IMPROVEMENTS_APPLIED.md  ← Full documentation
├── QUICK_REFERENCE.md       ← Quick guide
├── test_improvements.py     ← Test suite
│
└── jobautomation/
    ├── job_apply_all_platforms.py  ← Main bot (IMPROVED)
    ├── simple_config_loader.py     ← Config loader
    ├── .env                        ← Your credentials
    ├── config/
    │   └── config.json             ← Job preferences
    ├── logs/
    │   ├── job_automation_all_platforms.log
    │   ├── job_applications.db     ← SQLite database
    │   └── bot_console_output.log
    ├── screenshots/                ← Auto-captured screenshots
    ├── resumes/                    ← Your resume files
    └── cover_letters/              ← Your cover letters
```

---

## 🎯 Common Commands

### **Start Fresh Run**
```bash
# Delete old session data (optional)
rm -rf jobautomation/chrome_automation_profile/*

# Run bot
./RUN_JOB_BOT.sh
```

### **View Recent Activity**
```bash
tail -30 jobautomation/logs/job_automation_all_platforms.log
```

### **Count Applications**
```bash
python -c "
import sqlite3
conn = sqlite3.connect('jobautomation/logs/job_applications.db')
count = conn.execute('SELECT COUNT(*) FROM applications').fetchone()[0]
print(f'Total applications: {count}')
"
```

### **Export Database to CSV**
```bash
python -c "
import sqlite3
import csv

conn = sqlite3.connect('jobautomation/logs/job_applications.db')
cursor = conn.execute('SELECT * FROM applications')

with open('applications_export.csv', 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow([d[0] for d in cursor.description])
    writer.writerows(cursor.fetchall())

print('Exported to applications_export.csv')
"
```

### **Find Screenshots for Specific Platform**
```bash
# Windows
dir jobautomation\screenshots\dice*.png

# Linux/Mac
ls jobautomation/screenshots/dice*.png
```

---

## 🔍 Troubleshooting

### **Bot Won't Start**
```bash
# Check Python
python --version

# Check dependencies
pip install -r jobautomation/requirements.txt

# Check .env file exists
ls jobautomation/.env

# Run with verbose output
cd jobautomation && python job_apply_all_platforms.py
```

### **Chrome Won't Open**
```bash
# Check ChromeDriver
ls jobautomation/chromedriver-win64/chromedriver.exe

# Download manually if missing
# https://chromedriver.chromium.org/
```

### **Database Locked**
```bash
# Close any Python processes accessing it
pkill -f "python job_apply_all_platforms.py"

# Wait a few seconds and try again
```

### **Too Many Searches**
Edit `MAX_APPLICATIONS_PER_RUN` in `.env`:
```bash
MAX_APPLICATIONS_PER_RUN=10
```

---

## ⚡ Quick Actions

| Action | Command |
|--------|---------|
| **Start bot** | `./RUN_JOB_BOT.sh` or `RUN_JOB_BOT.bat` |
| **Stop bot** | `./STOP_BOT.sh` or `Ctrl+C` |
| **View logs** | `tail -f jobautomation/logs/*.log` |
| **Check stats** | `python VIEW_STATS.py` |
| **Test improvements** | `python test_improvements.py` |
| **View screenshots** | `ls jobautomation/screenshots/` |
| **Export data** | See "Export Database to CSV" above |

---

## 📈 Performance Tips

1. **Reduce interaction time** - Lower `manual_interaction_time` in config (default 45s)
2. **Limit platforms** - Disable slower platforms in `config.json`
3. **Increase max searches** - Set `MAX_APPLICATIONS_PER_RUN` higher
4. **Enable headless mode** - Set `HEADLESS_BROWSER=true` for faster execution
5. **Disable screenshots** - Set `SAVE_SCREENSHOTS=false` to save time

---

## 🎉 What's Improved

All scripts use the **improved version** with:
- ✅ Unique session IDs (no Chrome conflicts)
- ✅ UTF-8 encoding (no emoji crashes)
- ✅ SQLite database (duplicate prevention)
- ✅ Retry logic (3 attempts per search)
- ✅ Smart waits (dynamic page load detection)
- ✅ Random delays (human-like behavior)
- ✅ 5 new platforms added (Monster, CareerBuilder, etc.)
- ✅ Batch email support (enhanced validation)

---

**Last Updated:** 2025-11-07
**Status:** All improvements applied and tested ✓
