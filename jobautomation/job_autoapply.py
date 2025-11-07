"""
Job Auto-Application Script for Windows
Automates job applications on LinkedIn, Indeed, and ZipRecruiter
Sends email notifications via Gmail API
"""

import os
import time
import json
import pickle
import logging
from datetime import datetime
from typing import List, Dict, Optional

# Selenium imports
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import TimeoutException, NoSuchElementException
from webdriver_manager.chrome import ChromeDriverManager

# Gmail API imports
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import base64

# Beautiful Soup for parsing
from bs4 import BeautifulSoup

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/job_automation.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class JobAutoApply:
    """Main job application automation class"""

    def __init__(self, config_file: str = 'config/config.json'):
        """
        Initialize job automation bot

        Args:
            config_file: Path to configuration JSON file
        """
        logger.info("Initializing Job Auto-Apply Bot")

        # Load configuration
        with open(config_file, 'r') as f:
            self.config = json.load(f)

        # Personal information
        self.personal_info = self.config['personal_info']
        self.job_preferences = self.config['job_preferences']

        # Gmail API setup (only if email notifications are enabled)
        if self.config.get('automation_settings', {}).get('send_email_notifications', False):
            self.gmail_service = self._setup_gmail_api()
        else:
            self.gmail_service = None
            logger.info("Email notifications disabled - skipping Gmail API setup")

        # Selenium WebDriver setup
        self.driver = self._setup_selenium()

        # Application tracking
        self.applications_submitted = []
        self.applications_failed = []

        logger.info("Job Auto-Apply Bot initialized successfully")

    def _setup_gmail_api(self):
        """Set up Gmail API for sending notifications"""
        SCOPES = ['https://www.googleapis.com/auth/gmail.send']
        creds = None

        # Token file stores user's access and refresh tokens
        if os.path.exists('config/token.pickle'):
            with open('config/token.pickle', 'rb') as token:
                creds = pickle.load(token)

        # If no valid credentials, let user log in
        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                creds.refresh(Request())
            else:
                flow = InstalledAppFlow.from_client_secrets_file(
                    'config/credentials.json', SCOPES)
                creds = flow.run_local_server(port=0)

            # Save credentials for next run
            with open('config/token.pickle', 'wb') as token:
                pickle.dump(creds, token)

        return build('gmail', 'v1', credentials=creds)

    def _setup_selenium(self) -> webdriver.Chrome:
        """Set up Selenium WebDriver for Chrome"""
        chrome_options = Options()

        # Use a separate Chrome profile directory for automation
        # This avoids conflicts with running Chrome instances
        automation_profile = os.path.join(os.getcwd(), 'chrome_automation_profile')
        os.makedirs(automation_profile, exist_ok=True)
        chrome_options.add_argument(f'--user-data-dir={automation_profile}')
        chrome_options.add_argument('--profile-directory=Default')

        logger.info("Using dedicated automation Chrome profile")
        logger.info("IMPORTANT: Please log into LinkedIn and Indeed when browser opens")
        logger.info("The script will wait 120 seconds at each platform for you to log in")

        # Uncomment to run headless (no visible browser window)
        # chrome_options.add_argument('--headless=new')

        chrome_options.add_argument('--no-sandbox')
        chrome_options.add_argument('--disable-dev-shm-usage')
        chrome_options.add_argument('--disable-blink-features=AutomationControlled')
        chrome_options.add_argument('--start-maximized')

        # User agent to avoid bot detection
        chrome_options.add_argument(
            'user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        )

        # Disable automation flags
        chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
        chrome_options.add_experimental_option('useAutomationExtension', False)

        # Set download directory
        prefs = {
            "download.default_directory": os.path.join(os.getcwd(), "downloads"),
            "download.prompt_for_download": False,
        }
        chrome_options.add_experimental_option("prefs", prefs)

        # Create WebDriver with ChromeDriver
        # Try local chromedriver first, fall back to webdriver-manager
        local_chromedriver = os.path.join(os.getcwd(), 'chromedriver-win64', 'chromedriver.exe')
        if os.path.exists(local_chromedriver):
            service = Service(local_chromedriver)
            logger.info(f"Using local chromedriver: {local_chromedriver}")
        else:
            service = Service(ChromeDriverManager().install())
            logger.info("Using webdriver-manager to download chromedriver")

        driver = webdriver.Chrome(service=service, options=chrome_options)

        # Execute script to hide webdriver property
        driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")

        return driver

    def apply_linkedin_jobs(self):
        """Apply to jobs on LinkedIn"""
        logger.info("Starting LinkedIn job applications")

        try:
            # Navigate to LinkedIn
            self.driver.get('https://www.linkedin.com')
            time.sleep(5)

            # Check if already logged in by looking for the feed
            try:
                self.driver.find_element(By.ID, 'global-nav')
                logger.info("Already logged into LinkedIn - using existing session")
            except:
                # Not logged in, navigate to login page and wait for manual login
                logger.info("Not logged in to LinkedIn")
                self.driver.get('https://www.linkedin.com/login')
                time.sleep(3)

                # Check if login fields exist (might already be logged in via profile)
                try:
                    email_field = self.driver.find_element(By.ID, 'username')
                    logger.info("PLEASE LOG IN TO LINKEDIN MANUALLY NOW")
                    logger.info("Waiting 120 seconds for you to complete login...")
                    time.sleep(120)  # Wait 120 seconds for manual login
                except:
                    logger.info("Login page not found - you may already be logged in")
                    time.sleep(5)

            # Navigate to jobs page
            for job_title in self.job_preferences['job_titles']:
                for location in self.job_preferences['locations']:
                    self._search_linkedin_jobs(job_title, location)

        except Exception as e:
            logger.error(f"LinkedIn application error: {e}")

    def _search_linkedin_jobs(self, job_title: str, location: str):
        """
        Search for jobs on LinkedIn

        Args:
            job_title: Job title to search
            location: Location to search
        """
        logger.info(f"Searching LinkedIn: {job_title} in {location}")

        # Build search URL
        search_url = (
            f"https://www.linkedin.com/jobs/search/?"
            f"keywords={job_title.replace(' ', '%20')}&"
            f"location={location.replace(' ', '%20')}&"
            f"f_AL=true&"  # Easy Apply filter
            f"f_TPR=r86400"  # Posted in last 24 hours
        )

        self.driver.get(search_url)
        time.sleep(3)

        # Scroll to load all jobs
        self._scroll_page(3)

        # Get all job cards
        try:
            job_cards = self.driver.find_elements(
                By.CSS_SELECTOR,
                'div.job-card-container'
            )

            logger.info(f"Found {len(job_cards)} jobs on LinkedIn")

            for i, job_card in enumerate(job_cards[:10]):  # Apply to first 10
                try:
                    # Click job card
                    job_card.click()
                    time.sleep(2)

                    # Check if "Easy Apply" button exists
                    easy_apply_buttons = self.driver.find_elements(
                        By.XPATH,
                        "//button[contains(@class, 'jobs-apply-button') and contains(., 'Easy Apply')]"
                    )

                    if easy_apply_buttons:
                        self._apply_linkedin_easy_apply(job_card)
                    else:
                        logger.info(f"Job {i+1}: No Easy Apply button, skipping")

                except Exception as e:
                    logger.error(f"Error applying to job {i+1}: {e}")
                    continue

        except Exception as e:
            logger.error(f"Error finding job cards: {e}")

    def _apply_linkedin_easy_apply(self, job_card):
        """
        Apply to LinkedIn job using Easy Apply

        Args:
            job_card: Selenium WebElement of job card
        """
        try:
            # Get job title and company
            job_title = job_card.find_element(
                By.CSS_SELECTOR,
                'h3.base-search-card__title'
            ).text
            company = job_card.find_element(
                By.CSS_SELECTOR,
                'h4.base-search-card__subtitle'
            ).text

            logger.info(f"Applying to: {job_title} at {company}")

            # Click Easy Apply button
            easy_apply_button = self.driver.find_element(
                By.XPATH,
                "//button[contains(., 'Easy Apply')]"
            )
            easy_apply_button.click()
            time.sleep(2)

            # Fill application form
            self._fill_linkedin_application()

            # Track successful application
            self.applications_submitted.append({
                'platform': 'LinkedIn',
                'job_title': job_title,
                'company': company,
                'timestamp': datetime.now().isoformat()
            })

            logger.info(f"Successfully applied to {job_title} at {company}")

        except Exception as e:
            logger.error(f"Error during Easy Apply: {e}")
            self.applications_failed.append({
                'platform': 'LinkedIn',
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            })

    def _fill_linkedin_application(self):
        """Fill LinkedIn Easy Apply application form"""
        try:
            # Wait for modal to appear
            WebDriverWait(self.driver, 10).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, 'div.jobs-easy-apply-modal'))
            )

            # Fill phone number if requested
            try:
                phone_field = self.driver.find_element(By.CSS_SELECTOR, 'input[id*="phoneNumber"]')
                phone_field.clear()
                phone_field.send_keys(self.personal_info['phone'])
            except NoSuchElementException:
                pass

            # Upload resume if requested
            try:
                resume_upload = self.driver.find_element(By.CSS_SELECTOR, 'input[type="file"]')
                resume_path = os.path.abspath(self.personal_info['resume_path'])
                resume_upload.send_keys(resume_path)
                time.sleep(2)
            except NoSuchElementException:
                pass

            # Click through multi-page application
            max_pages = 5
            for page in range(max_pages):
                try:
                    # Look for "Next" button
                    next_button = self.driver.find_element(
                        By.XPATH,
                        "//button[contains(@aria-label, 'Continue to next step') or contains(., 'Next')]"
                    )
                    next_button.click()
                    time.sleep(2)

                except NoSuchElementException:
                    # No "Next" button, look for "Review" or "Submit"
                    try:
                        submit_button = self.driver.find_element(
                            By.XPATH,
                            "//button[contains(@aria-label, 'Submit application') or contains(., 'Submit')]"
                        )
                        submit_button.click()
                        time.sleep(3)
                        logger.info("Application submitted successfully")
                        break

                    except NoSuchElementException:
                        logger.warning("Could not find Submit button")
                        break

            # Close modal
            try:
                close_button = self.driver.find_element(
                    By.CSS_SELECTOR,
                    'button[aria-label="Dismiss"]'
                )
                close_button.click()
            except:
                pass

        except TimeoutException:
            logger.error("Application modal did not load in time")

    def apply_indeed_jobs(self):
        """Apply to jobs on Indeed"""
        logger.info("Starting Indeed job applications")

        try:
            self.driver.get('https://www.indeed.com')
            time.sleep(5)

            # Check if login is needed
            try:
                sign_in_button = self.driver.find_element(By.LINK_TEXT, 'Sign in')
                logger.info("Not logged into Indeed - if you need to log in, please do so now")
                logger.info("Waiting 120 seconds for manual login if needed...")
                time.sleep(120)
            except:
                logger.info("Already logged into Indeed or login not required")

            for job_title in self.job_preferences['job_titles']:
                for location in self.job_preferences['locations']:
                    self._search_indeed_jobs(job_title, location)

        except Exception as e:
            logger.error(f"Indeed application error: {e}")

    def _search_indeed_jobs(self, job_title: str, location: str):
        """
        Search for jobs on Indeed

        Args:
            job_title: Job title to search
            location: Location to search
        """
        logger.info(f"Searching Indeed: {job_title} in {location}")

        # Navigate to Indeed search
        self.driver.get('https://www.indeed.com')
        time.sleep(2)

        # Fill search form
        try:
            job_title_field = self.driver.find_element(By.ID, 'text-input-what')
            job_title_field.clear()
            job_title_field.send_keys(job_title)

            location_field = self.driver.find_element(By.ID, 'text-input-where')
            location_field.clear()
            location_field.send_keys(location)
            location_field.send_keys(Keys.RETURN)

            time.sleep(3)

            # Filter by "Easily apply"
            try:
                easy_apply_filter = self.driver.find_element(
                    By.XPATH,
                    "//a[contains(., 'Easily apply')]"
                )
                easy_apply_filter.click()
                time.sleep(2)
            except NoSuchElementException:
                logger.warning("Could not find 'Easily apply' filter")

            # Get job cards
            job_cards = self.driver.find_elements(
                By.CSS_SELECTOR,
                'div.job_seen_beacon'
            )

            logger.info(f"Found {len(job_cards)} jobs on Indeed")

            for i, job_card in enumerate(job_cards[:10]):
                try:
                    # Click job card
                    job_card.click()
                    time.sleep(2)

                    # Check for "Easily apply" button
                    easily_apply_buttons = self.driver.find_elements(
                        By.XPATH,
                        "//button[contains(., 'Easily apply') or contains(@id, 'applyButton')]"
                    )

                    if easily_apply_buttons:
                        self._apply_indeed_job(job_card)
                    else:
                        logger.info(f"Job {i+1}: No Easily apply button")

                except Exception as e:
                    logger.error(f"Error applying to Indeed job {i+1}: {e}")
                    continue

        except Exception as e:
            logger.error(f"Error searching Indeed: {e}")

    def _apply_indeed_job(self, job_card):
        """
        Apply to Indeed job

        Args:
            job_card: Selenium WebElement of job card
        """
        try:
            # Get job details
            job_title = job_card.find_element(By.CSS_SELECTOR, 'h2.jobTitle').text
            company = job_card.find_element(By.CSS_SELECTOR, 'span.companyName').text

            logger.info(f"Applying to: {job_title} at {company}")

            # Click apply button
            apply_button = self.driver.find_element(
                By.XPATH,
                "//button[contains(., 'Easily apply') or contains(@id, 'applyButton')]"
            )
            apply_button.click()
            time.sleep(2)

            # Fill application (simplified - Indeed varies widely)
            self._fill_indeed_application()

            self.applications_submitted.append({
                'platform': 'Indeed',
                'job_title': job_title,
                'company': company,
                'timestamp': datetime.now().isoformat()
            })

            logger.info(f"Successfully applied to {job_title} at {company}")

        except Exception as e:
            logger.error(f"Error during Indeed application: {e}")

    def _fill_indeed_application(self):
        """Fill Indeed application form"""
        try:
            # Upload resume if prompted
            try:
                resume_upload = self.driver.find_element(By.CSS_SELECTOR, 'input[type="file"]')
                resume_path = os.path.abspath(self.personal_info['resume_path'])
                resume_upload.send_keys(resume_path)
                time.sleep(2)
            except NoSuchElementException:
                pass

            # Fill phone if requested
            try:
                phone_field = self.driver.find_element(By.CSS_SELECTOR, 'input[name*="phone"]')
                phone_field.clear()
                phone_field.send_keys(self.personal_info['phone'])
            except NoSuchElementException:
                pass

            # Submit application
            try:
                submit_button = self.driver.find_element(
                    By.XPATH,
                    "//button[contains(., 'Submit') or contains(., 'Continue')]"
                )
                submit_button.click()
                time.sleep(3)
            except NoSuchElementException:
                logger.warning("Could not find submit button")

        except Exception as e:
            logger.error(f"Error filling Indeed application: {e}")

    def _scroll_page(self, scrolls: int = 3):
        """
        Scroll page to load dynamic content

        Args:
            scrolls: Number of times to scroll
        """
        for _ in range(scrolls):
            self.driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
            time.sleep(2)

    def send_email_notification(self):
        """Send email notification with application summary"""
        if not self.gmail_service:
            logger.info("Email notifications disabled - skipping email")
            return

        try:
            message = MIMEMultipart()
            message['to'] = self.personal_info['email']
            message['subject'] = f"Job Application Summary - {datetime.now().strftime('%Y-%m-%d')}"

            # Create email body
            body = f"""
Job Application Automation Summary
Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

SUCCESSFUL APPLICATIONS: {len(self.applications_submitted)}
{self._format_applications(self.applications_submitted)}

FAILED APPLICATIONS: {len(self.applications_failed)}
{self._format_applications(self.applications_failed)}

Total Applications: {len(self.applications_submitted) + len(self.applications_failed)}
Success Rate: {len(self.applications_submitted) / (len(self.applications_submitted) + len(self.applications_failed)) * 100:.1f}%

---
Automated by Job Auto-Apply Bot
            """

            message.attach(MIMEText(body, 'plain'))

            # Encode message
            raw_message = base64.urlsafe_b64encode(message.as_bytes()).decode('utf-8')

            # Send email
            self.gmail_service.users().messages().send(
                userId='me',
                body={'raw': raw_message}
            ).execute()

            logger.info("Email notification sent successfully")

        except Exception as e:
            logger.error(f"Error sending email notification: {e}")

    def _format_applications(self, applications: List[Dict]) -> str:
        """Format application list for email"""
        if not applications:
            return "  None\n"

        formatted = ""
        for app in applications:
            if 'job_title' in app:
                formatted += f"  - {app['job_title']} at {app['company']} ({app['platform']})\n"
            else:
                formatted += f"  - Error: {app['error']} ({app['platform']})\n"

        return formatted

    def save_application_log(self):
        """Save application log to JSON file"""
        log_data = {
            'timestamp': datetime.now().isoformat(),
            'successful': self.applications_submitted,
            'failed': self.applications_failed,
            'summary': {
                'total': len(self.applications_submitted) + len(self.applications_failed),
                'successful': len(self.applications_submitted),
                'failed': len(self.applications_failed)
            }
        }

        filename = f"logs/applications_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(filename, 'w') as f:
            json.dump(log_data, f, indent=2)

        logger.info(f"Application log saved to {filename}")

    def run(self):
        """Main execution method"""
        try:
            logger.info("Starting job application automation")

            # Apply to LinkedIn jobs
            if self.config.get('platforms', {}).get('linkedin', True):
                self.apply_linkedin_jobs()

            # Apply to Indeed jobs
            if self.config.get('platforms', {}).get('indeed', True):
                self.apply_indeed_jobs()

            # Send email notification
            self.send_email_notification()

            # Save application log
            self.save_application_log()

            logger.info("Job application automation completed")
            logger.info(f"Total applications submitted: {len(self.applications_submitted)}")

        except Exception as e:
            logger.error(f"Fatal error in automation: {e}")

        finally:
            # Close browser
            self.driver.quit()
            logger.info("Browser closed")


if __name__ == "__main__":
    # Run the automation
    bot = JobAutoApply(config_file='config/config.json')
    bot.run()
