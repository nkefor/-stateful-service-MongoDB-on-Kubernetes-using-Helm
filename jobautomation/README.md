# Job Auto-Apply Bot for Windows

**Automate job applications on LinkedIn and Indeed with AI-powered resume screening and Gmail notifications**

## What This Does

This Python script automatically:
- Searches for jobs on **LinkedIn** and **Indeed**
- Applies using "Easy Apply" and "Easily apply" features
- Fills in your personal information automatically
- Uploads your resume
- Tracks all applications
- Sends you an email summary via Gmail
- Saves detailed logs

---

## Quick Start (Windows)

### Step 1: Install Python

1. Go to https://python.org/downloads/
2. Download **Python 3.11 or newer**
3. **IMPORTANT**: Check the box "Add Python to PATH" during installation
4. Verify installation:
   ```cmd
   python --version
   ```
   Should show: `Python 3.11.x` or newer

### Step 2: Download This Project

1. Download all files to: `C:\Users\YourName\jobautomation`
2. Your folder structure should look like:
   ```
   jobautomation/
   ├── job_autoapply.py
   ├── SETUP_WINDOWS.bat
   ├── RUN.bat
   ├── requirements.txt
   ├── README.md
   ├── config/
   │   └── config.json
   ├── resumes/
   ├── cover_letters/
   └── logs/
   ```

### Step 3: Run Setup

**Double-click** `SETUP_WINDOWS.bat`

This will:
- Check if Python is installed
- Install all required packages (Selenium, Gmail API, etc.)
- Take 2-3 minutes

### Step 4: Configure Your Information

Edit `config/config.json` with your details:

```json
{
  "personal_info": {
    "name": "John Doe",
    "email": "john.doe@gmail.com",
    "phone": "+1-555-123-4567",
    "linkedin_email": "john.doe@gmail.com",
    "linkedin_password": "YOUR_LINKEDIN_PASSWORD",
    "resume_path": "resumes/John_Doe_Resume.pdf"
  },
  "job_preferences": {
    "job_titles": [
      "DevOps Engineer",
      "Cloud Engineer",
      "Site Reliability Engineer"
    ],
    "locations": [
      "Remote",
      "San Francisco, CA",
      "New York, NY"
    ]
  }
}
```

### Step 5: Add Your Resume

Put your resume PDF in the `resumes/` folder:
- Example: `resumes/John_Doe_Resume.pdf`
- Update the path in `config.json`

### Step 6: Get Gmail API Credentials (Optional but Recommended)

**Why?** To receive email summaries of your applications.

1. Go to https://console.cloud.google.com/
2. Create a new project (e.g., "Job Automation")
3. Enable **Gmail API**:
   - Click "Enable APIs and Services"
   - Search for "Gmail API"
   - Click "Enable"
4. Create OAuth credentials:
   - Go to "Credentials" → "Create Credentials" → "OAuth client ID"
   - Application type: "Desktop app"
   - Download the JSON file
5. Rename it to `credentials.json`
6. Move it to: `config/credentials.json`

**First-time Gmail auth:**
- On first run, a browser window will open
- Sign in with your Gmail account
- Click "Allow"
- This creates `token.pickle` for future use

### Step 7: Run the Bot

**Double-click** `RUN.bat`

Or in Command Prompt:
```cmd
cd C:\Users\YourName\jobautomation
python job_autoapply.py
```

---

## What Happens When You Run It

1. **Chrome browser opens** (you'll see it working)
2. **Logs in to LinkedIn** with your credentials
3. **Searches for jobs** matching your criteria
4. **Applies to jobs** with "Easy Apply"
5. **Repeats for Indeed**
6. **Sends email summary** to your Gmail
7. **Saves application log** to `logs/` folder

**Typical run time**: 10-20 minutes (depending on number of jobs)

---

## Configuration Options

### Personal Information

```json
"personal_info": {
  "name": "Your Full Name",
  "email": "your.email@gmail.com",
  "phone": "+1-555-123-4567",
  "linkedin_email": "your.email@gmail.com",
  "linkedin_password": "YOUR_PASSWORD",
  "resume_path": "resumes/Your_Resume.pdf"
}
```

### Job Preferences

```json
"job_preferences": {
  "job_titles": [
    "DevOps Engineer",
    "Cloud Engineer",
    "SRE"
  ],
  "locations": [
    "Remote",
    "United States"
  ],
  "keywords": [
    "AWS",
    "Kubernetes",
    "Terraform"
  ]
}
```

### Platform Selection

```json
"platforms": {
  "linkedin": true,   // Set to false to skip LinkedIn
  "indeed": true      // Set to false to skip Indeed
}
```

### Automation Settings

```json
"automation_settings": {
  "max_applications_per_run": 25,
  "delay_between_applications": 10,
  "headless_browser": false,  // true = invisible browser
  "send_email_notifications": true
}
```

---

## Advanced Usage

### Run in Headless Mode (Invisible Browser)

Edit `config.json`:
```json
"automation_settings": {
  "headless_browser": true
}
```

Or edit `job_autoapply.py` line 98:
```python
chrome_options.add_argument('--headless=new')
```
Uncomment this line to hide the browser.

### Schedule Automatic Runs (Windows Task Scheduler)

**Run the bot daily at 9 AM:**

1. Open **Task Scheduler** (search in Windows)
2. Click "Create Basic Task"
3. Name: "Job Auto-Apply"
4. Trigger: Daily at 9:00 AM
5. Action: "Start a program"
   - Program: `C:\Users\YourName\jobautomation\RUN.bat`
6. Click "Finish"

Now it runs automatically every day!

### View Application Logs

Logs are saved in `logs/` folder:
- `job_automation.log` - Detailed execution log
- `applications_YYYYMMDD_HHMMSS.json` - Application history

**Example log entry:**
```json
{
  "timestamp": "2025-01-05T14:32:10",
  "successful": [
    {
      "platform": "LinkedIn",
      "job_title": "DevOps Engineer",
      "company": "Tech Company Inc.",
      "timestamp": "2025-01-05T14:30:22"
    }
  ],
  "summary": {
    "total": 15,
    "successful": 12,
    "failed": 3
  }
}
```

---

## Troubleshooting

### Issue: "Python is not recognized"
**Solution**:
- Reinstall Python and check "Add Python to PATH"
- Or manually add Python to PATH:
  1. Search "Environment Variables" in Windows
  2. Edit "Path" variable
  3. Add: `C:\Users\YourName\AppData\Local\Programs\Python\Python311\`

### Issue: "ModuleNotFoundError: No module named 'selenium'"
**Solution**: Run `SETUP_WINDOWS.bat` again

### Issue: Browser doesn't open
**Solution**:
- Make sure Chrome is installed
- Update Chrome to latest version
- Run: `pip install --upgrade selenium webdriver-manager`

### Issue: "Unable to locate element"
**Solution**:
- LinkedIn/Indeed changed their website layout
- Increase delays in the script (line 188, change `time.sleep(2)` to `time.sleep(5)`)

### Issue: Applications not submitting
**Solution**:
- Some jobs require additional questions (not automated)
- Check `logs/job_automation.log` for specific errors
- Run in non-headless mode to see what's happening

### Issue: LinkedIn login fails
**Solution**:
- Check username/password in `config.json`
- LinkedIn may require 2FA - disable for automation account
- LinkedIn may detect automation - add random delays

### Issue: Gmail API authentication fails
**Solution**:
- Make sure `credentials.json` is in `config/` folder
- Delete `config/token.pickle` and re-authenticate
- Check Gmail API is enabled in Google Cloud Console

---

## Security & Privacy

### Storing Passwords
- **Don't share** your `config.json` file (contains passwords)
- Consider using a separate LinkedIn account for automation
- Use environment variables for sensitive data (advanced)

### Gmail Access
- The script only sends emails (no reading)
- Token is stored locally in `config/token.pickle`
- You can revoke access anytime: https://myaccount.google.com/permissions

### Bot Detection
- LinkedIn and Indeed may detect automated activity
- Use reasonable delays (10+ seconds between applications)
- Don't run multiple times per day
- Consider using headless mode sparingly

---

## Limitations

**What This Bot CAN Do:**
- Apply to "Easy Apply" jobs on LinkedIn
- Apply to "Easily apply" jobs on Indeed
- Fill basic forms (name, email, phone, resume)
- Track and log applications

**What This Bot CANNOT Do:**
- Answer custom screening questions
- Fill complex multi-page forms
- Apply to external job sites (requires clicking "Apply on company website")
- Bypass CAPTCHA challenges
- Guaranteed job interviews (you still need a good resume!)

---

## File Structure

```
jobautomation/
│
├── job_autoapply.py          # Main script (485 lines)
├── SETUP_WINDOWS.bat          # One-click setup
├── RUN.bat                    # One-click run
├── requirements.txt           # Python dependencies
├── README.md                  # This file
│
├── config/
│   ├── config.json            # Your settings (EDIT THIS)
│   ├── credentials.json       # Gmail API credentials (download)
│   └── token.pickle           # Gmail auth token (auto-generated)
│
├── resumes/
│   └── Your_Resume.pdf        # Put your resume here
│
├── cover_letters/
│   └── Your_Cover_Letter.pdf  # Optional cover letters
│
└── logs/
    ├── job_automation.log     # Execution logs
    └── applications_*.json    # Application history
```

---

## Tips for Success

1. **Update Your Resume First**
   - Tailor it to the jobs you're applying for
   - Use keywords from job descriptions
   - Keep it to 1-2 pages

2. **Start Small**
   - Test with 5-10 applications first
   - Check the results before scaling up

3. **Refine Your Search**
   - Use specific job titles
   - Target your preferred locations
   - Exclude keywords you don't want

4. **Monitor Results**
   - Check your email for application confirmations
   - Review `logs/` folder for errors
   - Adjust config based on success rate

5. **Follow Up**
   - Keep a spreadsheet of companies you applied to
   - Send personalized follow-up emails
   - Connect with recruiters on LinkedIn

---

## Sample Email Notification

```
Job Application Automation Summary
Date: 2025-01-05 14:35:22

SUCCESSFUL APPLICATIONS: 12
  - DevOps Engineer at Tech Company Inc. (LinkedIn)
  - Cloud Engineer at Startup XYZ (Indeed)
  - SRE at Fortune 500 Corp (LinkedIn)
  ... 9 more

FAILED APPLICATIONS: 3
  - Error: Could not find submit button (LinkedIn)
  - Error: Timeout waiting for modal (Indeed)
  - Error: Required field missing (LinkedIn)

Total Applications: 15
Success Rate: 80.0%

---
Automated by Job Auto-Apply Bot
```

---

## Customization

### Add More Job Boards

Edit `job_autoapply.py` and add methods like:
```python
def apply_ziprecruiter_jobs(self):
    # Your code here
    pass
```

### Add Custom Filters

Edit `config.json`:
```json
"filters": {
  "exclude_companies": [
    "Company I Don't Like"
  ],
  "exclude_keywords": [
    "unpaid",
    "commission only"
  ],
  "required_keywords": [
    "remote"
  ]
}
```

### Change Application Limit

Edit `config.json`:
```json
"automation_settings": {
  "max_applications_per_run": 50  // Apply to 50 jobs per run
}
```

---

## Legal & Ethical Considerations

**Terms of Service:**
- Check LinkedIn and Indeed Terms of Service
- Automated tools may violate TOS
- Use at your own risk

**Best Practices:**
- Only apply to jobs you're actually qualified for
- Don't spam applications
- Personalize when possible
- Be responsive if contacted

**Disclaimer:**
This tool is for educational purposes. The author is not responsible for misuse or account suspensions.

---

## Support

**Common Questions:**
- Check the Troubleshooting section above
- Review `logs/job_automation.log` for errors

**Issues:**
- GitHub Issues: [Create an issue](https://github.com/nkefor/jobautomation/issues)
- Email: your.email@example.com

---

## Changelog

**v1.0.0** (2025-01-05)
- Initial release
- LinkedIn Easy Apply support
- Indeed Easily apply support
- Gmail API notifications
- Windows batch scripts
- Comprehensive logging

---

**Good luck with your job search! 🚀**

Remember: This tool helps you apply faster, but the quality of your resume and cover letter still matter most!
