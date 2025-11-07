# How To Run Job Automation on Your Local Machine

## 🚀 Quick Start (Easiest Way)

### Step 1: Double-Click This File
```
RUN_ME_FIRST.bat
```

That's it! The script will:
- ✅ Check Python installation
- ✅ Install all packages
- ✅ Help you configure settings
- ✅ Run the automation

---

## 📋 What You Need Before Running

### 1. Your Information
Edit `config\config.json` and update:
- **Line 3**: Your full name
- **Line 4**: Your email address
- **Line 5**: Your phone number
- **Line 7**: Your LinkedIn password
- **Line 8**: Your resume filename

### 2. Your Resume
Put your resume PDF in the `resumes\` folder:
- File must be PDF format
- Example: `resumes\John_Doe_Resume.pdf`
- Update the path in config.json

### 3. Google Chrome
Make sure Google Chrome is installed:
- Download from: https://www.google.com/chrome

---

## 🎯 Step-by-Step Instructions

### Method 1: Automated Setup (Recommended)

**Just double-click:** `RUN_ME_FIRST.bat`

The script will guide you through everything!

### Method 2: Manual Setup

If the automated script doesn't work, follow these steps:

#### Step 1: Install Packages
Open Command Prompt in this folder and run:
```cmd
python -m pip install -r requirements.txt
```

Or double-click: `INSTALL_NOW.bat`

#### Step 2: Edit Config
Open `config\config.json` in Notepad and update your information.

#### Step 3: Add Resume
Copy your resume PDF to the `resumes\` folder.

#### Step 4: Run
```cmd
python job_autoapply.py
```

Or double-click: `RUN.bat`

---

## 🔧 Troubleshooting

### "Python is not recognized"
**Solution**: Install Python from https://python.org/downloads/
- ✓ Check "Add Python to PATH" during installation

### "ModuleNotFoundError"
**Solution**: Run `INSTALL_NOW.bat` or:
```cmd
python -m pip install selenium webdriver-manager google-api-python-client beautifulsoup4
```

### "Could not find Chrome"
**Solution**: Install Google Chrome from https://google.com/chrome

### LinkedIn Login Fails
**Solution**:
- Check your password in `config\config.json`
- Make sure 2FA is disabled on your LinkedIn account (for automation)

### No Jobs Found
**Solution**:
- Check your job_titles in config.json (make them more specific)
- Try broader locations (e.g., "Remote" or "United States")

---

## 📊 What Happens When You Run It

1. **Chrome Opens** - You'll see the browser window
2. **LinkedIn Login** - Logs in with your credentials
3. **Job Search** - Searches for jobs matching your criteria
4. **Auto-Apply** - Clicks "Easy Apply" and fills forms
5. **Indeed** - Repeats process on Indeed
6. **Email Summary** - Sends results to your Gmail (if configured)
7. **Logs Saved** - Check `logs\` folder for details

**Typical Duration**: 15-30 minutes for 25 applications

---

## 📧 Gmail Notifications (Optional)

To receive email summaries:

1. Go to https://console.cloud.google.com/
2. Create a new project
3. Enable "Gmail API"
4. Create OAuth credentials (Desktop app)
5. Download `credentials.json`
6. Move to: `config\credentials.json`
7. First run will ask for Gmail authorization

---

## 🎯 Tips for First Run

### Start Small
Edit `config\config.json` line 50:
```json
"max_applications_per_run": 5
```
This applies to only 5 jobs for testing.

### Watch It Work
Make sure line 52 is:
```json
"headless_browser": false
```
This lets you see the browser working.

### Check Results
After the first run:
- Open `logs\job_automation.log`
- Open `logs\applications_*.json`
- Check your LinkedIn for applications

---

## 📁 Important Files

| File | Purpose |
|------|---------|
| **RUN_ME_FIRST.bat** | Main setup and run script |
| **config\config.json** | Your settings (EDIT THIS) |
| **resumes\** | Put your resume here |
| **job_autoapply.py** | Main automation script |
| **logs\** | Application logs appear here |

---

## ⚙️ Configuration Quick Reference

### Personal Info (Lines 2-9)
```json
"personal_info": {
  "name": "John Doe",                    ← Change this
  "email": "john.doe@gmail.com",         ← Change this
  "phone": "+1-555-123-4567",            ← Change this
  "linkedin_password": "YOUR_PASSWORD",   ← Change this
  "resume_path": "resumes/Your_Resume.pdf" ← Change this
}
```

### Job Preferences (Lines 12-40)
```json
"job_preferences": {
  "job_titles": [
    "DevOps Engineer",        ← Add/remove job titles you want
    "Cloud Engineer"
  ],
  "locations": [
    "Remote",                 ← Add/remove locations
    "San Francisco, CA"
  ]
}
```

### Application Settings (Lines 49-54)
```json
"automation_settings": {
  "max_applications_per_run": 25,  ← How many jobs to apply to
  "headless_browser": false,       ← false = see browser, true = invisible
  "send_email_notifications": true ← Email summary after run
}
```

---

## 🔒 Security Notes

### Config File Contains Password
- ⚠️ Don't share `config\config.json`
- ⚠️ Don't commit to public GitHub
- ✅ Keep it in this folder only

### LinkedIn Automation
- May violate LinkedIn Terms of Service
- Consider using a separate account
- Don't run multiple times per day

---

## 📈 Expected Results

### First Run (5-10 jobs)
- Success rate: 60-80%
- Some jobs may require manual questions
- Check logs for details

### After Tuning
- Apply to 25+ jobs per run
- Higher success rate with right filters
- Daily runs for best results

---

## 🎓 Next Steps After First Run

1. **Review Logs**
   - Open `logs\job_automation.log`
   - See which jobs succeeded/failed

2. **Adjust Config**
   - Refine job_titles
   - Adjust locations
   - Add filters

3. **Schedule Daily Runs**
   - Use Windows Task Scheduler
   - Run every morning at 9 AM
   - Automate your job search!

4. **Track Applications**
   - Keep a spreadsheet
   - Note which companies contacted you
   - Improve your approach

---

## 🆘 Need Help?

**Check these files**:
- `TROUBLESHOOTING.md` - Detailed solutions
- `README.md` - Comprehensive guide
- `logs\job_automation.log` - See what went wrong

**Common Issues**:
- Python not found → Install Python
- Packages not installed → Run INSTALL_NOW.bat
- Config errors → Edit config\config.json
- Browser issues → Install Chrome

---

## ✅ Checklist Before Running

- [ ] Python 3.11+ installed
- [ ] Packages installed (run INSTALL_NOW.bat)
- [ ] config\config.json edited with YOUR info
- [ ] Resume PDF in resumes\ folder
- [ ] Google Chrome installed
- [ ] LinkedIn account ready (password correct)

**All checked? Double-click RUN_ME_FIRST.bat!**

---

## 🎉 You're Ready!

The job automation system is set up and ready to use.

**To start:**
```
Double-click: RUN_ME_FIRST.bat
```

Good luck with your job search! 🚀

---

*Location: C:\Users\keff2\email-automation\jobautomation\*
*Last Updated: 2025-01-05*
