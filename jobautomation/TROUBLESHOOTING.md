# Troubleshooting Guide - Job Auto-Apply Bot

## Common Issues and Solutions

### 1. Python Installation Issues

#### Error: "python is not recognized as an internal or external command"

**Cause**: Python not installed or not in PATH

**Solution**:
```cmd
# Method 1: Reinstall Python
1. Go to python.org/downloads
2. Download Python 3.11+
3. ✓ CHECK: "Add Python to PATH" during install
4. Click "Install Now"
5. Restart Command Prompt
6. Test: python --version
```

**Method 2: Add Python to PATH manually**:
```cmd
1. Search "Environment Variables" in Windows
2. Click "Environment Variables" button
3. Under "System variables", find "Path"
4. Click "Edit"
5. Click "New"
6. Add: C:\Users\YourName\AppData\Local\Programs\Python\Python311\
7. Add: C:\Users\YourName\AppData\Local\Programs\Python\Python311\Scripts\
8. Click OK
9. Restart Command Prompt
```

---

### 2. Package Installation Issues

#### Error: "ModuleNotFoundError: No module named 'selenium'"

**Solution**:
```cmd
cd C:\Users\YourName\jobautomation
pip install -r requirements.txt
```

Or install individually:
```cmd
pip install selenium
pip install webdriver-manager
pip install google-api-python-client
pip install google-auth
pip install google-auth-oauthlib
pip install beautifulsoup4
```

#### Error: "pip is not recognized"

**Solution**:
```cmd
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

---

### 3. Browser/ChromeDriver Issues

#### Error: "SessionNotCreatedException: session not created"

**Cause**: Chrome version mismatch with ChromeDriver

**Solution**:
```cmd
pip install --upgrade selenium webdriver-manager
```

The `webdriver-manager` will automatically download the correct ChromeDriver.

#### Browser doesn't open at all

**Solutions**:
1. **Install Google Chrome**: Download from google.com/chrome
2. **Check Chrome installation**:
   ```cmd
   "C:\Program Files\Google\Chrome\Application\chrome.exe" --version
   ```
3. **Update Chrome** to latest version
4. **Restart computer** (sometimes needed after Chrome install)

---

### 4. LinkedIn Issues

#### Error: "Unable to locate element with ID 'username'"

**Cause**: LinkedIn changed their login page

**Solution**:
```python
# Edit job_autoapply.py line 150-160
# Try different selectors:
email_field = self.driver.find_element(By.NAME, 'session_key')
password_field = self.driver.find_element(By.NAME, 'session_password')
```

#### LinkedIn login fails even with correct password

**Possible causes**:
1. **2FA enabled** - Disable for automation account
2. **CAPTCHA** - LinkedIn detected automation
3. **Account locked** - Too many login attempts

**Solutions**:
- Use a separate LinkedIn account for automation
- Add random delays:
  ```python
  import random
  time.sleep(random.uniform(3, 7))
  ```
- Run less frequently (once per day max)

#### "Easy Apply" button not found

**Cause**: LinkedIn redesign or job doesn't have Easy Apply

**Check**:
```python
# Edit job_autoapply.py to add logging
easy_apply_buttons = self.driver.find_elements(...)
logger.info(f"Found {len(easy_apply_buttons)} Easy Apply buttons")
```

---

### 5. Indeed Issues

#### Job cards not loading

**Solution**: Increase scroll wait time
```python
# Edit job_autoapply.py _scroll_page method
def _scroll_page(self, scrolls: int = 3):
    for _ in range(scrolls):
        self.driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        time.sleep(5)  # Changed from 2 to 5
```

#### "Easily apply" button not clicking

**Debug**:
```python
# Add this before clicking
button = self.driver.find_element(By.XPATH, "...")
self.driver.execute_script("arguments[0].scrollIntoView();", button)
time.sleep(1)
button.click()
```

---

### 6. Gmail API Issues

#### Error: "credentials.json not found"

**Solution**:
1. Go to https://console.cloud.google.com/
2. Create/select project
3. Enable Gmail API
4. Create OAuth credentials (Desktop app)
5. Download JSON file
6. Rename to `credentials.json`
7. Move to: `config/credentials.json`

#### Browser doesn't open for Gmail authorization

**Solution**:
```cmd
# Delete old token and re-authenticate
del config\token.pickle
python job_autoapply.py
```

#### Error: "insufficient authentication scopes"

**Solution**: Delete token and re-authenticate with correct scopes
```cmd
del config\token.pickle
python job_autoapply.py
```

---

### 7. Configuration Issues

#### Resume not uploading

**Check**:
1. File exists: `resumes/Your_Resume.pdf`
2. Path in config.json is correct:
   ```json
   "resume_path": "resumes/Your_Resume.pdf"
   ```
3. File is PDF format (not .docx)
4. Filename has no special characters

**Test path**:
```python
import os
print(os.path.abspath("resumes/Your_Resume.pdf"))
print(os.path.exists("resumes/Your_Resume.pdf"))
```

#### JSON parsing error in config.json

**Common mistakes**:
```json
// ❌ WRONG: Missing comma
{
  "name": "John"
  "email": "john@example.com"
}

// ✅ CORRECT: Has comma
{
  "name": "John",
  "email": "john@example.com"
}

// ❌ WRONG: Trailing comma
{
  "name": "John",
  "email": "john@example.com",
}

// ✅ CORRECT: No trailing comma
{
  "name": "John",
  "email": "john@example.com"
}
```

**Validate JSON**:
- Use https://jsonlint.com/
- Or in Python:
  ```cmd
  python -m json.tool config/config.json
  ```

---

### 8. Automation Detection

#### LinkedIn/Indeed blocking the bot

**Signs**:
- Login page keeps reloading
- CAPTCHA appears frequently
- Account gets locked

**Solutions**:
1. **Add random delays**:
   ```python
   import random
   time.sleep(random.uniform(5, 10))
   ```

2. **Use realistic user agent**:
   ```python
   chrome_options.add_argument(
       'user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
       'AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36'
   )
   ```

3. **Don't run headless**:
   ```python
   # Comment out this line:
   # chrome_options.add_argument('--headless=new')
   ```

4. **Run less frequently**: Once per day maximum

5. **Simulate human behavior**:
   ```python
   from selenium.webdriver.common.action_chains import ActionChains

   actions = ActionChains(self.driver)
   actions.move_to_element(element).pause(random.uniform(0.5, 1.5)).click().perform()
   ```

---

### 9. Application Not Submitting

#### Application gets stuck on screening questions

**Cause**: Bot can't answer custom questions

**Solution**: These require manual application. Skip them:
```python
# Check for screening questions
screening_questions = self.driver.find_elements(
    By.CSS_SELECTOR,
    'input[type="text"], textarea'
)
if len(screening_questions) > 3:
    logger.info("Too many screening questions, skipping")
    return
```

#### Multi-page application timeout

**Solution**: Increase max_pages
```python
# Edit job_autoapply.py line 280
max_pages = 10  # Increased from 5
```

---

### 10. Performance Issues

#### Script running too slowly

**Solutions**:
1. **Reduce applications per run**:
   ```json
   "max_applications_per_run": 10
   ```

2. **Decrease delays** (carefully):
   ```python
   time.sleep(1)  # Instead of time.sleep(5)
   ```

3. **Run headless** (faster):
   ```json
   "headless_browser": true
   ```

#### Chrome using too much memory

**Solution**: Restart browser periodically
```python
# After every 10 applications
if i % 10 == 0:
    self.driver.quit()
    self.driver = self._setup_selenium()
```

---

## Debugging Steps

### 1. Enable Verbose Logging

Edit `job_autoapply.py` line 30:
```python
logging.basicConfig(
    level=logging.DEBUG,  # Changed from INFO
    ...
)
```

### 2. Take Screenshots

Add to script:
```python
self.driver.save_screenshot(f'logs/screenshot_{datetime.now().strftime("%Y%m%d_%H%M%S")}.png')
```

### 3. Print Page Source

```python
print(self.driver.page_source)
```

### 4. Check Element Exists

```python
try:
    element = self.driver.find_element(By.ID, 'username')
    print("Element found!")
except NoSuchElementException:
    print("Element NOT found")
    print("Available elements:", self.driver.page_source)
```

### 5. Use Browser DevTools

1. Run without headless mode
2. Right-click element → Inspect
3. Copy XPath/CSS Selector
4. Use in script

---

## Getting Help

### Check Logs First

**Main log**:
```cmd
notepad logs\job_automation.log
```

**Application history**:
```cmd
notepad logs\applications_20250105_143000.json
```

### Test Individual Components

**Test LinkedIn login**:
```python
from selenium import webdriver
from selenium.webdriver.common.by import By
import time

driver = webdriver.Chrome()
driver.get('https://www.linkedin.com/login')
time.sleep(2)

email_field = driver.find_element(By.ID, 'username')
email_field.send_keys('your.email@gmail.com')

password_field = driver.find_element(By.ID, 'password')
password_field.send_keys('your_password')
password_field.submit()

time.sleep(5)
input("Press Enter to close...")
driver.quit()
```

**Test Gmail API**:
```python
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
import pickle

with open('config/token.pickle', 'rb') as token:
    creds = pickle.load(token)

service = build('gmail', 'v1', credentials=creds)
print("Gmail API connected successfully!")
```

---

## Still Having Issues?

### Report a Bug

**Include in your report**:
1. Error message (full traceback)
2. `logs/job_automation.log` file
3. Python version: `python --version`
4. Operating system version
5. Chrome version
6. Steps to reproduce

**Where to report**:
- GitHub Issues: [Create issue](https://github.com/nkefor/jobautomation/issues)
- Email: support@example.com

### Emergency Fix: Revert to Defaults

```cmd
cd C:\Users\YourName\jobautomation
git clone https://github.com/nkefor/jobautomation.git jobautomation-fresh
xcopy jobautomation-fresh\*.* .\ /E /Y
```

---

## Prevention Tips

1. **Backup your config**:
   ```cmd
   copy config\config.json config\config.backup.json
   ```

2. **Test before running**:
   - Set `max_applications_per_run` to 3
   - Run and verify it works
   - Then increase to 25

3. **Monitor logs**:
   ```cmd
   tail -f logs\job_automation.log
   ```

4. **Use version control**:
   ```cmd
   git init
   git add .
   git commit -m "Working configuration"
   ```

5. **Keep packages updated**:
   ```cmd
   pip install --upgrade -r requirements.txt
   ```

---

**Last Updated**: 2025-01-05
