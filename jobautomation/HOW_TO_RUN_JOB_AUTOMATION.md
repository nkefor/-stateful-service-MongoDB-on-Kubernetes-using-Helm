# How to Run Job Automation - Quick Guide

## ⚡ Quick Start (Easiest Method)

### Double-click this file:
```
START_JOB_HUNT.bat
```

That's it! The batch file will:
1. Check all requirements
2. Install packages
3. Show configuration summary
4. Ask for confirmation
5. Start the automation

---

## 🎯 What Happens When You Run It

### Step 1: Pre-Flight Checks
The script verifies:
- ✅ `.env` file exists (your credentials)
- ✅ `config/config.json` exists
- ✅ Resume PDF exists
- ✅ Logs directory created

### Step 2: Package Installation
Automatically installs:
- `selenium` (browser automation)
- `webdriver-manager` (ChromeDriver)
- `beautifulsoup4` (HTML parsing)

### Step 3: Configuration Summary
Shows your settings:
- Name: Hansen Nkefor
- Email: hansen.nkefor@gmail.com
- 5 job titles being searched
- 11+ locations being searched
- 20+ platforms enabled

### Step 4: Browser Automation Starts
- Opens Chrome browser (visible window)
- Visits each enabled job platform
- Waits 120 seconds for you to log in manually
- Searches for jobs matching your criteria

---

## 📋 Your Current Configuration

### Job Titles:
- DevOps Engineer
- Cloud Engineer
- Site Reliability Engineer
- Infrastructure Engineer
- Platform Engineer

### Locations:
- Remote, Hybrid, Onsite
- Atlanta, GA
- Alpharetta, GA
- Dallas, TX
- Houston, TX
- Austin, TX
- San Antonio, TX
- Texas (statewide)
- North Carolina
- Florida
- Alabama
- Tennessee
- Arizona
- United States (nationwide)

### Platforms Enabled (All 20+):
1. LinkedIn
2. Indeed
3. Dice
4. ZipRecruiter
5. Monster
6. Glassdoor
7. CareerBuilder
8. BuiltIn
9. JobRight AI
10. Remote.co
11. FlexJobs
12. Wellfound
13. WeWorkRemotely
14. Remotive
15. LetsWorkRemotely
16. Toptal
17. Hired
18. AngelList
19. TheLadders
20. Zapier Jobs
21. Flexa
22. NoDesk
23. DynamiteJobs

### Automation Settings:
- Max applications: 25 per run
- Delay between apps: 10 seconds
- Browser mode: Visible (not headless)
- Screenshots: Enabled
- Email notifications: Disabled

---

## 🎬 What You'll See

### When the Script Runs:

1. **Chrome Opens Automatically**
   - A Chrome window will open
   - You'll see "Chrome is being controlled by automated test software"
   - This is normal!

2. **Platform Navigation**
   - The script visits each platform (LinkedIn, Indeed, etc.)
   - Waits 120 seconds for manual login if needed
   - Then searches for jobs

3. **Manual Login Required**
   - When Chrome opens to a platform, check if you're logged in
   - If not, log in manually within 120 seconds
   - The script will wait for you

4. **Job Searching**
   - Script fills in search forms automatically
   - Searches for your job titles
   - Filters by locations
   - May click "Apply" buttons (platform dependent)

5. **Logs Created**
   - All actions logged to `logs/job_automation.log`
   - Application summary saved to `logs/applications_*.json`

---

## ⚠️ Important Notes

### Before Running:

✅ **Check Your Credentials**
- Make sure `.env` has correct LinkedIn password
- Verify resume path is correct
- Double-check email address

✅ **Browser Requirements**
- Google Chrome must be installed
- Close other Chrome windows (recommended)
- Disable Chrome extensions that might interfere

✅ **Internet Connection**
- Stable internet required
- Avoid VPNs (may trigger CAPTCHAs)

✅ **Time Commitment**
- Plan for 1-2 hours of supervised automation
- You'll need to handle logins and CAPTCHAs
- Stay near the computer

### During the Run:

⚠️ **Manual Intervention Needed For:**
- Logging into platforms (first time)
- Solving CAPTCHAs
- Answering platform-specific questions
- Handling "Apply with Resume" vs "Easy Apply"

⚠️ **Don't:**
- Close the Chrome window manually
- Close the command prompt window
- Use the computer for other tasks (may interfere)

### After the Run:

✅ **Check Logs:**
```
logs/job_automation.log          ← Detailed activity log
logs/applications_*.json         ← Summary of applications
```

✅ **Follow Up:**
- Check your email for confirmations
- Review applications on each platform
- Customize applications as needed

---

## 🔧 Troubleshooting

### "Python not found"
**Solution:**
```bash
# Check if Python installed
python --version

# If not, download from python.org
# Install Python 3.8 or higher
```

### "Module not found: selenium"
**Solution:**
```bash
# Install manually
python -m pip install selenium==4.16.0
python -m pip install webdriver-manager==4.0.1
```

### "ChromeDriver not found"
**Solution:**
- Make sure Google Chrome is installed
- Script will auto-download ChromeDriver
- Or manually place in `chromedriver-win64/` folder

### "Configuration validation failed"
**Solution:**
```bash
# Test configuration
python simple_config_loader.py

# If errors, check .env file
notepad .env
```

### Python Installation Broken
If you see: `Fatal Python error: Failed to import encodings module`

**Solution:**
1. Uninstall Python completely
2. Download fresh installer from python.org
3. During install, check "Add Python to PATH"
4. Reinstall packages: `pip install -r requirements.txt`

### Browser Not Opening
**Solutions:**
- Verify Chrome is installed
- Check ChromeDriver version matches Chrome
- Try running: `python -m selenium.webdriver.chrome.service`

---

## 🚀 Alternative Run Methods

### Method 1: Batch File (Recommended)
```bash
START_JOB_HUNT.bat
```

### Method 2: Python Direct
```bash
python job_autoapply_enhanced.py
```

### Method 3: Test Config First
```bash
# Test configuration loading
python simple_config_loader.py

# If successful, then run automation
python job_autoapply_enhanced.py
```

### Method 4: Manual Step-by-Step
```bash
# 1. Check config
python simple_config_loader.py

# 2. Install packages
pip install -r requirements.txt

# 3. Create logs directory
mkdir logs

# 4. Run automation
python job_autoapply_enhanced.py
```

---

## 📊 Expected Results

### After One Run (25 applications):
- 20+ platforms visited
- 5 job titles × 13 locations = 65 search combinations
- Limited to 25 applications per run
- Logs showing:
  - Platforms visited
  - Searches performed
  - Jobs found
  - Applications attempted
  - Successes and failures

### Application Success Rate:
- **LinkedIn:** High (Easy Apply feature)
- **Indeed:** Medium (some require external redirects)
- **Dice:** Medium (profile required)
- **Others:** Varies by platform

---

## 🎯 Tips for Best Results

### Before First Run:
1. **Set up profiles** on main platforms manually
2. **Upload resume** to LinkedIn, Indeed, Dice
3. **Complete profiles** to 100%
4. **Save payment info** (if required for premium jobs)

### During Automation:
1. **Stay present** - don't leave unattended
2. **Help with CAPTCHAs** - can't be automated
3. **Monitor console** for errors
4. **Take notes** of interesting jobs

### After Automation:
1. **Review applications** - make sure they submitted
2. **Customize** any generic applications
3. **Follow up** on interesting positions
4. **Update your .env** with better keywords if needed

---

## 🔒 Security Reminder

**CRITICAL: Your credentials are in `.env`**

- ✅ `.env` is git-ignored
- ✅ Never share `.env` file
- ✅ Change LinkedIn password after testing
- ✅ Enable 2FA on all job platforms

**After running:**
- Review `chrome_automation_profile/` - contains login sessions
- Check `logs/` directory - may contain personal data
- Both are git-ignored for your protection

---

## 📝 Customizing Your Search

### To Change Job Titles:
Edit `.env` or `config/config.json` (not recommended)
Better: Use `.env` if you set up variables for job titles

### To Change Locations:
Edit `config/config.json`:
```json
"locations": [
  "Remote",
  "Your City, State",
  "Another Location"
]
```

### To Disable Platforms:
Edit `config/config.json`:
```json
"platforms": {
  "linkedin": true,
  "indeed": false,  ← Disable by setting to false
  "dice": true
}
```

### To Change Max Applications:
Edit `.env`:
```
MAX_APPLICATIONS_PER_RUN=50
```

---

## 🆘 Need Help?

### Log Files:
```
logs/job_automation.log          ← Main log file
logs/applications_*.json         ← Application results
```

### Configuration Files:
```
.env                            ← Your credentials (check this first)
config/config.json             ← Job preferences
simple_config_loader.py        ← Test with this
```

### Test Commands:
```bash
# Test config
python simple_config_loader.py

# Test Python
python --version

# Test Selenium
python -c "import selenium; print('Selenium OK')"
```

---

## ✅ Pre-Flight Checklist

Before running, verify:
- [ ] Python installed (3.8+)
- [ ] Google Chrome installed
- [ ] `.env` file exists with credentials
- [ ] Resume PDF exists in `resumes/`
- [ ] Logged into LinkedIn manually at least once
- [ ] Stable internet connection
- [ ] 1-2 hours available
- [ ] Computer won't auto-sleep

---

## 🎉 You're Ready!

**To start:**
```
Double-click: START_JOB_HUNT.bat
```

**Good luck with your job search!**

---

**Last Updated:** 2025-11-05
**For:** Hansen Nkefor
**Contact:** hansen.nkefor@gmail.com
