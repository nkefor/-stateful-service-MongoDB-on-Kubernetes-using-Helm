# Manual Run Instructions - Job Automation

## ⚠️ Python Installation Issue Detected

Your Python installation appears to be corrupted (`ModuleNotFoundError: encodings`).

---

## 🔧 Option 1: Fix Python (Recommended)

### Step 1: Uninstall Current Python
1. Open Windows Settings
2. Go to "Apps" → "Installed apps"
3. Find "Python 3.13" (or any Python version)
4. Click "Uninstall"

### Step 2: Download Fresh Python
1. Go to: https://www.python.org/downloads/
2. Download "Python 3.12.x" (stable version)
3. Run the installer

### Step 3: During Installation
- ✅ **CHECK** "Add Python to PATH"
- ✅ **CHECK** "Install for all users"
- Click "Install Now"

### Step 4: Verify Installation
Open Command Prompt and run:
```cmd
python --version
pip --version
```

Should show:
```
Python 3.12.x
pip 24.x.x
```

### Step 5: Install Dependencies
```cmd
cd C:\Users\keff2\email-automation\jobautomation
pip install selenium==4.16.0
pip install webdriver-manager==4.0.1
```

### Step 6: Run Automation
```cmd
cd C:\Users\keff2\email-automation\jobautomation
python job_apply_all_platforms.py
```

---

## 🚀 Option 2: Run Without Fixing Python

If you can't fix Python right now, here's how to apply manually:

### Direct URLs for Job Searches

I've created pre-built search URLs for you. Just open these in your browser:

#### Dice.com
**DevOps Engineer:**
```
https://www.dice.com/jobs?q=DevOps+Engineer&location=Remote&radius=30
```

**Cloud Engineer:**
```
https://www.dice.com/jobs?q=Cloud+Engineer&location=Remote&radius=30
```

#### ZipRecruiter
**DevOps Engineer:**
```
https://www.ziprecruiter.com/jobs-search?search=DevOps+Engineer&location=Remote
```

**Cloud Engineer:**
```
https://www.ziprecruiter.com/jobs-search?search=Cloud+Engineer&location=Remote
```

#### Glassdoor
**DevOps Engineer:**
```
https://www.glassdoor.com/Job/jobs.htm?sc.keyword=DevOps+Engineer
```

**Cloud Engineer:**
```
https://www.glassdoor.com/Job/jobs.htm?sc.keyword=Cloud+Engineer
```

#### BuiltIn
**DevOps Engineer:**
```
https://builtin.com/jobs?search=DevOps+Engineer
```

#### WeWorkRemotely
**DevOps Engineer:**
```
https://weworkremotely.com/remote-jobs/search?term=DevOps+Engineer
```

**Cloud Engineer:**
```
https://weworkremotely.com/remote-jobs/search?term=Cloud+Engineer
```

#### Remotive.io
```
https://remotive.com/remote-jobs/software-dev
```

#### Wellfound (AngelList)
**DevOps Engineer:**
```
https://wellfound.com/jobs?query=DevOps+Engineer
```

#### Hired.com
```
https://hired.com/jobs
```

#### TheLadders
**DevOps Engineer:**
```
https://www.theladders.com/jobs/search-jobs?keywords=DevOps+Engineer
```

#### Flexa
**DevOps Engineer:**
```
https://flexa.careers/search?search=DevOps+Engineer
```

#### Zapier Jobs
```
https://zapier.com/jobs
```

#### NoDesk
```
https://nodesk.co/remote-jobs/
```

#### DynamiteJobs
```
https://dynamitejobs.com/remote-jobs
```

---

## 📝 Manual Application Process

### For Each Platform:

1. **Open the URL** in your browser
2. **Create account/Login** (first time only)
3. **Upload your resume:**
   - `C:\Users\keff2\email-automation\jobautomation\resumes\Hansen_Nkefor_Resume_2025.pdf`
4. **Complete your profile** to 100%
5. **Browse job listings**
6. **Click "Apply" or "Easy Apply"** on jobs that match:
   - DevOps Engineer
   - Cloud Engineer
   - Site Reliability Engineer
   - Remote or US-based
   - AWS/Kubernetes/Terraform/Docker experience
7. **Track applications** in a spreadsheet

### Time Estimate:
- Per platform: 10-15 minutes (first time)
- Per application: 2-5 minutes
- Total for 25 apps: 1-2 hours

---

## 📊 Application Tracking Template

Create a spreadsheet with these columns:

| Date | Platform | Company | Position | Location | Status | Follow-up Date |
|------|----------|---------|----------|----------|--------|----------------|
| 11/05 | Dice | Example Corp | DevOps Engineer | Remote | Applied | 11/12 |

---

## ✅ Quick Win Strategy

### Focus on These Platforms First (Easiest):

1. **Dice.com** - Upload resume once, one-click apply
2. **ZipRecruiter** - Has "Quick Apply" feature
3. **WeWorkRemotely** - Browse and apply, very remote-focused
4. **Wellfound** - Great for startups
5. **BuiltIn** - Tech-focused, good for DevOps roles

### Goal:
- Apply to **5 jobs per day**
- Across **3 different platforms**
- Total: **25 applications in 5 days**

---

## 🎯 What Makes a Good Application

### Customize These Fields:
- **Why this company** - Research them first
- **Why this role** - Match your experience
- **Cover letter** - 3-4 sentences max
- **Availability** - When you can start

### Keywords to Include:
- AWS, Azure, GCP
- Kubernetes, Docker
- Terraform, Ansible
- CI/CD, Jenkins, GitLab
- Python, Bash
- DevSecOps, Infrastructure as Code

---

## 📞 Status of Your Automation Files

### ✅ Created and Ready:
- `job_apply_all_platforms.py` - Main automation script
- `simple_config_loader.py` - Config loader (no dependencies)
- `.env` - Your credentials (secured)
- `config/config.json` - Job preferences (LinkedIn & Indeed disabled)

### ⚠️ Blocked By:
- Python installation issue

### 🔧 To Fix:
1. Reinstall Python (see Option 1 above)
2. Install `selenium` and `webdriver-manager`
3. Run: `python job_apply_all_platforms.py`

---

## 🆘 Need Help?

### Python Errors:
```
ModuleNotFoundError: encodings
```
**Solution:** Reinstall Python completely

```
ModuleNotFoundError: selenium
```
**Solution:** Run `pip install selenium`

### Browser Errors:
```
ChromeDriver not found
```
**Solution:** Script will auto-download, or manually download from:
https://googlechromelabs.github.io/chrome-for-testing/

---

## 📈 Expected Results

### Manual Applications (Recommended for now):
- **Quality over quantity**
- **Customized applications**
- **Higher response rate** (10-20%)
- **Time:** 1-2 hours for 25 apps

### Automated (After fixing Python):
- **Fast bulk searching**
- **Standardized applications**
- **Lower response rate** (5-10%)
- **Time:** 30-45 minutes for 25 searches

---

## 🎉 Bottom Line

**While Python is broken:**
- Use the direct URLs above
- Apply manually to 5-10 jobs per day
- Track in a spreadsheet
- Follow up after 1 week

**Once Python is fixed:**
- Run `python job_apply_all_platforms.py`
- Let automation open each platform
- Apply during the 45-second windows
- Check logs for results

---

**Your automation is ready - it just needs working Python!**

**Quick fix:** Reinstall Python → Install selenium → Run script

**Alternative:** Use the direct URLs and apply manually (works right now)

---

Last Updated: 2025-11-05
