# Quick Start Guide

Get your email automation up and running in 5 minutes!

## Step 1: Install Dependencies (1 minute)

```bash
cd email-automation
pip install python-dotenv
```

## Step 2: Set Up Gmail App Password (2 minutes)

1. Go to: https://myaccount.google.com/apppasswords
2. Click "Select app" → Choose "Mail"
3. Click "Select device" → Choose "Other" → Type "Email Automation"
4. Click "Generate"
5. Copy the 16-character password

## Step 3: Configure Environment (1 minute)

```bash
# Copy the template
cp .env.example .env

# Edit .env and add your credentials:
SENDER_EMAIL=youremail@gmail.com
SENDER_PASSWORD=your16charpassword
RECIPIENT_EMAIL=recipient@gmail.com
```

## Step 4: Test It (1 minute)

```bash
python email_automation.py
```

You should see:
```
2025-10-28 14:00:00 - __main__ - INFO - EmailAutomation initialized successfully
2025-10-28 14:00:01 - __main__ - INFO - Email sent successfully to recipient@gmail.com
2025-10-28 14:00:01 - __main__ - INFO - Daily report email sent successfully!
```

## Done! 🎉

Check your recipient's inbox for the email.

## Next Steps

- Customize `generate_report()` function with your data
- Set up scheduling (Windows Task Scheduler or cron)
- Add HTML templates
- Include attachments

## Troubleshooting

**"Authentication failed"** → Use App Password, not regular password
**"Connection timeout"** → Check firewall/internet connection
**"Module not found"** → Run `pip install python-dotenv`

## Common Use Cases

### Send to Multiple Recipients
```python
recipients = ["user1@gmail.com", "user2@gmail.com"]
for recipient in recipients:
    email_client.send_email(recipient, subject, body)
```

### Add Attachments
```python
email_client.send_email(
    recipient_email="user@example.com",
    subject="Report",
    body="See attached",
    attachments=["report.pdf"]
)
```

### Schedule Daily (Windows)
1. Task Scheduler → Create Basic Task
2. Trigger: Daily at 9:00 AM
3. Action: Start program → `python`
4. Arguments: `C:\path\to\email_automation.py`

### Schedule Daily (Linux/Mac)
```bash
crontab -e
# Add: 0 9 * * * cd /path/to/email-automation && python3 email_automation.py
```

---

**Need help?** Check README.md for detailed documentation.
