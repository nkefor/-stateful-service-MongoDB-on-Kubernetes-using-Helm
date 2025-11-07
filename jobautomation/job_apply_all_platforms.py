"""
Comprehensive Job Auto-Application Script

This script automates job searches across multiple platforms.
It is designed to be modular, allowing for easy addition and configuration of new job boards.
It can automatically perform "Easy Apply" on supported platforms and send an email summary.

"""

import os
import pickle
import base64
import time
import json
import logging
import uuid
import sqlite3
import random
from datetime import datetime
from urllib.parse import quote_plus, urlencode
from typing import Dict, Any, List, Optional

# Securely load configuration from .env and config.json
# Ensure simple_config_loader.py is in the same directory or accessible
from simple_config_loader import load_config, print_config_summary

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import TimeoutException, NoSuchElementException

# Gmail API imports for email notifications (optional)
try:
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from googleapiclient.discovery import build
    GMAIL_API_AVAILABLE = True
except ImportError:
    GMAIL_API_AVAILABLE = False
    logger = logging.getLogger(__name__)

from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# --- Logging Configuration ---
os.makedirs('logs', exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/job_automation_all_platforms.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class ComprehensiveJobAutoApply:
    """
    A job application bot that automates searching on multiple platforms.
    It generates search URLs based on config, visits them, and allows for manual application.
    """

    # --- Platform Configuration ---
    # This dictionary drives the search logic for each platform.
    # To add a new platform, add an entry here and enable it in config.json.
    PLATFORM_CONFIGS = {
        'dice': {
            'url_template': 'https://www.dice.com/jobs?q={title}&location={location}&radius=30',
            'name': 'Dice.com'
        },
        'ziprecruiter': {
            'url_template': 'https://www.ziprecruiter.com/jobs/search?search={title}&location={location}',
            'name': 'ZipRecruiter'
        },
        'glassdoor': {
            'url_template': 'https://www.glassdoor.com/Job/jobs.htm?sc.keyword={title}',
            'name': 'Glassdoor'
        },
        'indeed': {
            'url_template': 'https://www.indeed.com/jobs?q={title}&l={location}',
            'name': 'Indeed'
        },
        'linkedin': {
            'url_template': 'https://www.linkedin.com/jobs/search/?keywords={title}&location={location}',
            'name': 'LinkedIn'
        },
        'builtin': {
            'url_template': 'https://builtin.com/jobs?search={title}',
            'name': 'BuiltIn'
        },
        'jobright_ai': {
            'url_template': 'https://jobright.ai/jobs?q={title}&location={location}',
            'name': 'JobRight.AI'
        },
        'weworkremotely': {
            'url_template': 'https://weworkremotely.com/remote-jobs/search?term={title}',
            'name': 'WeWorkRemotely'
        },
        'remotive': {
            'url_template': 'https://remotive.com/remote-jobs/software-dev', # This one doesn't take search terms in URL
            'name': 'Remotive.io'
        },
        'letsworkremotely': {
            'url_template': 'https://letsworkremotely.com/remote-jobs/search?term={title}',
            'name': 'LetsWorkRemotely'
        },
        'toptal': {
            'url_template': 'https://www.toptal.com/jobs',
            'name': 'Toptal'
        },
        'hired': {
            'url_template': 'https://hired.com/jobs',
            'name': 'Hired.com'
        },
        'wellfound': { # Formerly AngelList
            'url_template': 'https://wellfound.com/jobs?query={title}',
            'name': 'Wellfound (AngelList)'
        },
        'theladders': {
            'url_template': 'https://www.theladders.com/jobs/search-jobs?keywords={title}',
            'name': 'TheLadders.com'
        },
        'flexa': {
            'url_template': 'https://flexa.careers/search?query={title}',
            'name': 'Flexa.com'
        },
        'zapier': {
            'url_template': 'https://zapier.com/jobs',
            'name': 'Zapier Jobs'
        },
        'nodesk': {
            'url_template': 'https://nodesk.co/remote-jobs/search/?query={title}',
            'name': 'NoDesk.co'
        },
        'dynamitejobs': {
            'url_template': 'https://dynamitejobs.com/remote-jobs?q={title}',
            'name': 'DynamiteJobs.com'
        },
        'monster': {
            'url_template': 'https://www.monster.com/jobs/search?q={title}&where={location}',
            'name': 'Monster.com'
        },
        'careerbuilder': {
            'url_template': 'https://www.careerbuilder.com/jobs?keywords={title}&location={location}',
            'name': 'CareerBuilder'
        },
        'remote_co': {
            'url_template': 'https://remote.co/remote-jobs/search/?search_keywords={title}',
            'name': 'Remote.co'
        },
        'flexjobs': {
            'url_template': 'https://www.flexjobs.com/search?search={title}&location={location}',
            'name': 'FlexJobs'
        },
        'angellist': {
            'url_template': 'https://angel.co/jobs?query={title}',
            'name': 'AngelList'
        }
    }

    def __init__(self, config_file: str = 'config/config.json'):
        logger.info("="*70)
        logger.info(" COMPREHENSIVE JOB AUTO-APPLY BOT")
        logger.info("="*70)

        # Generate unique session ID for this run
        self.session_id = datetime.now().strftime('%Y%m%d_%H%M%S') + '_' + str(uuid.uuid4())[:8]
        logger.info(f"Session ID: {self.session_id}")

        self.config = load_config(config_file)
        self.personal_info = self.config['personal_info']
        self.job_preferences = self.config['job_preferences']
        self.platforms = self.config.get('platforms', {})
        self.automation_settings = self.config.get('automation_settings', {
            'headless_browser': False,
            'save_screenshots': True,
            'max_searches_per_run': 25,
            'delay_between_searches': 10,
            'manual_interaction_time': 0,
            'send_email_notifications': False
        })

        if print_config_summary:
            print_config_summary(self.config)
        logger.info(f"Config loaded for: {self.personal_info.get('name')}")

        # Initialize database
        self.db_path = 'logs/job_applications.db'
        self._init_database()

        self.driver = self._setup_selenium()
        self.gmail_service = self._setup_gmail_api() if self.automation_settings.get('send_email_notifications') else None

        self.jobs_visited = []
        self.applications_submitted = []
        self.applications_failed = []

        logger.info("Bot initialized successfully\n")

    def _init_database(self):
        """Initialize SQLite database for tracking applications"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()

            # Create applications table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS applications (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    session_id TEXT,
                    platform TEXT,
                    platform_name TEXT,
                    job_title TEXT,
                    company TEXT,
                    location TEXT,
                    url TEXT UNIQUE,
                    page_title TEXT,
                    status TEXT,
                    error_message TEXT,
                    timestamp TEXT,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            ''')

            # Create index on URL for fast duplicate checking
            cursor.execute('''
                CREATE INDEX IF NOT EXISTS idx_url ON applications(url)
            ''')

            # Create index on timestamp for efficient queries
            cursor.execute('''
                CREATE INDEX IF NOT EXISTS idx_timestamp ON applications(timestamp)
            ''')

            conn.commit()
            conn.close()
            logger.info(f"Database initialized: {self.db_path}")
        except Exception as e:
            logger.error(f"Failed to initialize database: {e}")
            raise

    def _check_duplicate_application(self, url: str) -> bool:
        """Check if we've already applied to this job"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute('SELECT COUNT(*) FROM applications WHERE url = ?', (url,))
            count = cursor.fetchone()[0]
            conn.close()
            return count > 0
        except Exception as e:
            logger.error(f"Error checking duplicates: {e}")
            return False

    def _save_application_to_db(self, job_data: Dict[str, Any]):
        """Save application to database"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute('''
                INSERT OR IGNORE INTO applications
                (session_id, platform, platform_name, job_title, company, location, url, page_title, status, error_message, timestamp)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                self.session_id,
                job_data.get('platform', ''),
                job_data.get('platform_name', ''),
                job_data.get('title', ''),
                job_data.get('company', ''),
                job_data.get('location', ''),
                job_data.get('url', ''),
                job_data.get('page_title', ''),
                job_data.get('status', 'visited'),
                job_data.get('error', ''),
                job_data.get('timestamp', datetime.now().isoformat())
            ))
            conn.commit()
            conn.close()
        except Exception as e:
            logger.error(f"Error saving to database: {e}")

    def _setup_gmail_api(self):
        """Set up Gmail API for sending notifications if enabled."""
        if not GMAIL_API_AVAILABLE:
            logger.info("Gmail API not available (install google-auth packages). Email notifications disabled.")
            return None

        logger.info("Setting up Gmail API for email notifications...")
        SCOPES = ['https://www.googleapis.com/auth/gmail.send']
        creds = None
        token_path = 'config/token.pickle'
        creds_path = 'config/credentials.json'

        if not os.path.exists(creds_path):
            logger.warning(f"Gmail 'credentials.json' not found at '{creds_path}'. Email notifications disabled.")
            return None

        if os.path.exists(token_path):
            with open(token_path, 'rb') as token:
                creds = pickle.load(token)

        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                creds.refresh(Request())
            else:
                flow = InstalledAppFlow.from_client_secrets_file(creds_path, SCOPES)
                creds = flow.run_local_server(port=0)
            with open(token_path, 'wb') as token:
                pickle.dump(creds, token)

        logger.info("Gmail API setup successful.")
        return build('gmail', 'v1', credentials=creds)


    def _setup_selenium(self):
        """Setup Chrome WebDriver with unique profile per session"""
        chrome_options = Options()

        # Use unique profile directory for this session to avoid conflicts
        automation_profile = os.path.join(os.getcwd(), 'chrome_automation_profile', self.session_id)
        os.makedirs(automation_profile, exist_ok=True)
        chrome_options.add_argument(f'--user-data-dir={automation_profile}')
        logger.info(f"Using Chrome profile: {automation_profile}")

        if self.automation_settings.get('headless_browser'):
            chrome_options.add_argument('--headless=new')
            logger.info("Running in HEADLESS mode")
        else:
            logger.info("Running with VISIBLE browser")

        chrome_options.add_argument('--no-sandbox')
        chrome_options.add_argument('--disable-dev-shm-usage')
        chrome_options.add_argument('--disable-blink-features=AutomationControlled')
        chrome_options.add_argument('--start-maximized')
        chrome_options.add_argument(
            'user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        )

        chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
        chrome_options.add_experimental_option('useAutomationExtension', False)

        local_chromedriver = os.path.join(os.getcwd(), 'chromedriver-win64', 'chromedriver.exe')
        if os.path.exists(local_chromedriver):
            service = Service(local_chromedriver)
        else:
            try:
                from webdriver_manager.chrome import ChromeDriverManager
                service = Service(ChromeDriverManager().install())
            except Exception as e:
                logger.error(f"Could not use webdriver-manager: {e}")
                service = Service()

        driver = webdriver.Chrome(service=service, options=chrome_options)
        driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
        return driver

    def generate_search_urls(self) -> List[Dict[str, Any]]:
        """Generate URLs for all enabled platforms"""
        urls = []
        job_titles = self.job_preferences.get('job_titles', [])
        locations = self.job_preferences.get('locations', [])

        # Get enabled platforms from config.json
        enabled_platforms = [
            platform for platform, enabled in self.platforms.items()
            if enabled
        ]

        logger.info(f"Enabled platforms ({len(enabled_platforms)}): {', '.join(enabled_platforms)}")
        logger.info(f"Job Titles: {', '.join(job_titles)}")
        logger.info(f"Locations: {', '.join(locations)}")

        # Generate URLs for each combination
        for platform_key in enabled_platforms:
            if platform_key not in self.PLATFORM_CONFIGS:
                logger.warning(f"Platform '{platform_key}' is enabled but not configured in PLATFORM_CONFIGS, skipping.")
                continue

            config = self.PLATFORM_CONFIGS[platform_key]

            for title in job_titles:
                for location in locations:
                    url = config['url_template'].format(
                        title=quote_plus(title),
                        location=quote_plus(location)
                    )

                    urls.append({
                        'platform': platform_key,
                        'platform_name': config['name'],
                        'title': title,
                        'location': location,
                        'url': url
                    })

        logger.info(f"Generated {len(urls)} search URLs\n")
        return urls

    def visit_job_search(self, search_info: Dict[str, Any], retry_count: int = 0):
        """Visit a job search URL with retry logic and duplicate checking"""
        platform = search_info['platform']
        platform_name = search_info['platform_name']
        title = search_info['title']
        location = search_info['location']
        url = search_info['url']

        logger.info("-" * 70)
        logger.info(f"Platform: {platform_name}")
        logger.info(f"Searching: {title} | {location}")
        logger.info(f"URL: {url}")

        # Check for duplicates
        if self._check_duplicate_application(url):
            logger.info("SKIPPED: Already visited this search URL previously")
            return

        max_retries = 3
        try:
            self.driver.get(url)

            # Intelligent wait for page load instead of fixed sleep
            try:
                WebDriverWait(self.driver, 15).until(
                    lambda d: d.execute_script('return document.readyState') == 'complete'
                )
                # Add random delay to appear more human-like
                time.sleep(random.uniform(2, 4))
            except TimeoutException:
                logger.warning("Page load timeout, continuing anyway...")

            page_title = self.driver.title
            logger.info(f"Page loaded: {page_title}")

            # --- Attempt "Easy Apply" if enabled ---
            easy_apply_enabled = self.automation_settings.get('easy_apply_enabled', False)
            if easy_apply_enabled and platform in ['linkedin', 'indeed']: # Add other platforms here
                self._attempt_easy_apply(platform)

            # Screenshot if enabled with improved naming
            if self.automation_settings.get('save_screenshots'):
                screenshot_dir = 'screenshots'
                os.makedirs(screenshot_dir, exist_ok=True)
                timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                # Add unique suffix to prevent collisions
                unique_id = str(uuid.uuid4())[:6]
                safe_title = title.replace(' ', '_')[:20]
                screenshot_path = os.path.join(screenshot_dir, f"{platform}_{safe_title}_{timestamp}_{unique_id}.png")
                self.driver.save_screenshot(screenshot_path)
                logger.info(f"Screenshot: {screenshot_path}")

            # Record visit
            job_data = {
                'platform': platform,
                'platform_name': platform_name,
                'title': title,
                'location': location,
                'url': url,
                'page_title': page_title,
                'status': 'visited',
                'timestamp': datetime.now().isoformat()
            }
            self.jobs_visited.append(job_data)

            # Save to database
            self._save_application_to_db(job_data)

            # Manual interaction time with random variation
            interaction_time = self.automation_settings.get('manual_interaction_time', 45)
            if not self.automation_settings.get('headless_browser') and interaction_time and interaction_time > 0:
                # Add randomness to interaction time
                actual_time = int(interaction_time * random.uniform(0.9, 1.1))
                logger.info(f"\n>>> INTERACTIVE MODE: {actual_time} seconds for manual actions <<<")
                logger.info("    - Log in if needed")
                logger.info("    - Browse job listings")
                logger.info("    - Click 'Apply' on jobs you like")
                logger.info(f"    - Browser will auto-advance in {actual_time} seconds\n")
                time.sleep(actual_time)
            else:
                time.sleep(8)

            logger.info(f"[CHECK MARK] Completed: {platform_name}")

        except Exception as e:
            error_msg = str(e)[:200]
            logger.error(f"[X] Error on {platform_name}: {error_msg}")

            # Retry logic with exponential backoff
            if retry_count < max_retries:
                wait_time = 2 ** retry_count  # 1s, 2s, 4s
                logger.info(f"Retrying in {wait_time} seconds... (Attempt {retry_count + 1}/{max_retries})")
                time.sleep(wait_time)
                return self.visit_job_search(search_info, retry_count + 1)
            else:
                logger.error(f"Max retries reached for {platform_name}. Moving on.")
                failed_job_data = {
                    'platform': platform,
                    'platform_name': platform_name,
                    'title': title,
                    'location': location,
                    'url': url,
                    'error': error_msg,
                    'status': 'failed',
                    'timestamp': datetime.now().isoformat()
                }
                self.applications_failed.append(failed_job_data)
                # Save failed attempt to database
                self._save_application_to_db(failed_job_data)

    def _attempt_easy_apply(self, platform: str):
        """Dispatcher for platform-specific 'Easy Apply' logic."""
        logger.info(f"Attempting 'Easy Apply' on {platform}...")
        
        if platform == 'linkedin':
            self._apply_on_linkedin()
        elif platform == 'indeed':
            self._apply_on_indeed()
        else:
            logger.warning(f"No 'Easy Apply' logic implemented for {platform}")

    def _apply_on_linkedin(self):
        """Finds and applies to 'Easy Apply' jobs on LinkedIn."""
        # Scroll to load job listings
        for _ in range(3):
            self.driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
            time.sleep(2)

        try:
            job_cards = self.driver.find_elements(By.CSS_SELECTOR, 'div.job-search-card')
            logger.info(f"Found {len(job_cards)} job cards on LinkedIn.")

            for i, card in enumerate(job_cards[:10]): # Limit to first 10 jobs per search
                try:
                    self.driver.execute_script("arguments[0].scrollIntoView(true);", card)
                    card.click()
                    time.sleep(2) # Wait for job details to load

                    # Get job details from the right-hand pane
                    job_title = self.driver.find_element(By.CSS_SELECTOR, 'h2.top-card-layout__title').text
                    company = self.driver.find_element(By.CSS_SELECTOR, 'a.topcard__org-name-link').text
                    
                    # Find the "Easy Apply" button in the details pane
                    easy_apply_button = self.driver.find_element(By.XPATH, "//button[contains(@class, 'jobs-apply-button')]//span[text()='Easy Apply']")
                    easy_apply_button.click()
                    
                    logger.info(f"[{i+1}/{len(job_cards)}] Applying to: {job_title} at {company}")
                    
                    # Fill the application form
                    self._fill_linkedin_form(job_title, company)

                except NoSuchElementException:
                    logger.info(f"[{i+1}/{len(job_cards)}] Job is not 'Easy Apply', skipping.")
                    continue
                except Exception as e:
                    logger.error(f"Error processing LinkedIn job card {i+1}: {str(e)[:100]}")
                    self.driver.find_element(By.TAG_NAME, 'body').send_keys(Keys.ESCAPE) # Close modal if stuck
                    time.sleep(1)

        except Exception as e:
            logger.error(f"Error finding LinkedIn job cards: {e}")

    def _fill_linkedin_form(self, job_title: str, company: str):
        """Fills out the multi-step LinkedIn 'Easy Apply' modal."""
        try:
            # Wait for the modal to appear
            WebDriverWait(self.driver, 10).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, 'div.jobs-easy-apply-modal'))
            )

            # Navigate through the form pages
            for _ in range(5): # Max 5 pages
                # Fill phone number if requested
                try:
                    phone_field = self.driver.find_element(By.CSS_SELECTOR, 'input[id*="phoneNumber"]')
                    if not phone_field.get_attribute('value'):
                        phone_field.send_keys(self.personal_info.get('phone', ''))
                except NoSuchElementException:
                    pass

                # Check for "Next" or "Submit" button
                try:
                    next_button = self.driver.find_element(By.XPATH, "//button[contains(@aria-label, 'Continue to next step')]")
                    next_button.click()
                    time.sleep(2)
                except NoSuchElementException:
                    # If "Next" not found, try to submit
                    submit_button = self.driver.find_element(By.XPATH, "//button[contains(@aria-label, 'Submit application')]")
                    submit_button.click()
                    logger.info(f"SUCCESS: Application for '{job_title}' submitted.")
                    self.applications_submitted.append({'platform': 'LinkedIn', 'title': job_title, 'company': company})
                    time.sleep(3) # Wait for confirmation
                    return # Exit after successful submission

            logger.warning("Exceeded max pages in LinkedIn form, closing modal.")

        except Exception as e:
            logger.error(f"Error filling LinkedIn form for '{job_title}': {e}")
        finally:
            # Always try to close the modal
            try:
                self.driver.find_element(By.CSS_SELECTOR, 'button[aria-label="Dismiss"]').click()
            except:
                pass # Modal may already be closed

    def _apply_on_indeed(self):
        """Finds and applies to 'Apply now' jobs on Indeed."""
        try:
            # Indeed loads jobs in an iframe sometimes, or via JS.
            # We will find the list of jobs and click each one.
            job_list = WebDriverWait(self.driver, 15).until(
                EC.presence_of_element_located((By.ID, "jobsearch-ResultsList"))
            )
            job_cards = job_list.find_elements(By.CSS_SELECTOR, "div.job_seen_beacon")
            logger.info(f"Found {len(job_cards)} job cards on Indeed.")

            for i, card in enumerate(job_cards[:10]): # Limit to first 10 jobs
                try:
                    self.driver.execute_script("arguments[0].scrollIntoView({block: 'center'});", card)
                    
                    # Get job title and company from the card directly
                    job_title = card.find_element(By.CSS_SELECTOR, 'h2.jobTitle > a > span').text
                    company = card.find_element(By.CSS_SELECTOR, 'span.companyName').text

                    # Click the card to open the details pane
                    card.click()
                    time.sleep(2)

                    # The details pane is in an iframe
                    details_pane = WebDriverWait(self.driver, 10).until(
                        EC.presence_of_element_located((By.ID, "vjs-container"))
                    )
                    
                    # Check for the "Apply now" button
                    apply_button = details_pane.find_element(By.XPATH, ".//button[contains(@class, 'indeed-apply-button')] | .//span[contains(text(), 'Apply now')]")
                    
                    logger.info(f"[{i+1}/{len(job_cards)}] Applying to: {job_title} at {company}")
                    apply_button.click()
                    
                    # The application form opens in a new iframe
                    self._fill_indeed_form(job_title, company)

                except NoSuchElementException:
                    logger.info(f"[{i+1}/{len(job_cards)}] Job is not 'Apply now', skipping.")
                    continue
                except Exception as e:
                    logger.error(f"Error processing Indeed job card {i+1}: {str(e)[:100]}")
                    # Try to close any pop-ups/iframes
                    self.driver.find_element(By.TAG_NAME, 'body').send_keys(Keys.ESCAPE)
                    time.sleep(1)

        except TimeoutException:
            logger.error("Could not find job list on Indeed. Page structure may have changed.")
        except Exception as e:
            logger.error(f"Error finding Indeed job cards: {e}")

    def _fill_indeed_form(self, job_title: str, company: str):
        """Fills out the Indeed application form, which appears in an iframe."""
        try:
            # Switch to the application iframe
            WebDriverWait(self.driver, 10).until(
                EC.frame_to_be_available_and_switch_to_it((By.CSS_SELECTOR, "iframe[title='Job application form']"))
            )

            # Indeed forms vary. We'll look for a "Continue" button and click it until it's gone.
            for _ in range(5): # Max 5 pages
                try:
                    continue_button = self.driver.find_element(By.XPATH, "//button[contains(text(), 'Continue')]")
                    continue_button.click()
                    time.sleep(2)
                except NoSuchElementException:
                    # No more "Continue" buttons, assume we are on the final page.
                    logger.info("Application submitted or reached final step.")
                    self.applications_submitted.append({'platform': 'Indeed', 'title': job_title, 'company': company})
                    break

        except TimeoutException:
            logger.error(f"Indeed application iframe did not appear for '{job_title}'.")
        except Exception as e:
            logger.error(f"Error filling Indeed form for '{job_title}': {e}")
        finally:
            # IMPORTANT: Switch back to the main content from the iframe
            self.driver.switch_to.default_content()

    def send_email_notification(self):
        """Send email notification with application summary."""
        if not self.gmail_service:
            logger.info("Email service not configured or disabled. Skipping notification.")
            return

        try:
            message = MIMEMultipart()
            message['to'] = self.personal_info['email']
            message['subject'] = f"Job Application Summary - {datetime.now().strftime('%Y-%m-%d')}"

            total_apps = len(self.applications_submitted) + len(self.applications_failed)
            success_rate = (len(self.applications_submitted) / total_apps * 100) if total_apps > 0 else 0

            body = f"""
Job Automation Summary
Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

SUCCESSFUL APPLICATIONS: {len(self.applications_submitted)}
{self._format_apps_for_email(self.applications_submitted)}

FAILED/SKIPPED SEARCHES: {len(self.applications_failed)}
{self._format_apps_for_email(self.applications_failed, is_failure=True)}

Total Searches Attempted: {len(self.jobs_visited)}
Success Rate: {success_rate:.1f}%
---
Automated by Gemini Code Assist Bot
            """
            message.attach(MIMEText(body, 'plain'))
            raw_message = base64.urlsafe_b64encode(message.as_bytes()).decode('utf-8')

            self.gmail_service.users().messages().send(userId='me', body={'raw': raw_message}).execute()
            logger.info("Email notification sent successfully.")

        except Exception as e:
            logger.error(f"Error sending email notification: {e}")

    def _format_apps_for_email(self, apps: List[Dict], is_failure=False) -> str:
        """Format application list for email."""
        if not apps:
            return "  None\n"
        lines = []
        for app in apps:
            if is_failure:
                lines.append(f"  - {app['platform_name']}: {app.get('error', 'Unknown error')}")
            else:
                lines.append(f"  - {app['title']} at {app['company']} ({app['platform']})")
        return "\n".join(lines) + "\n"

    def save_log(self):
        """Save comprehensive log"""
        log_data = {
            'run_timestamp': datetime.now().isoformat(),
            'config': {
                'name': self.personal_info.get('name'),
                'job_titles': self.job_preferences.get('job_titles'),
                'platforms_attempted': list(set([j['platform_name'] for j in self.jobs_visited]))
            },
            'jobs_visited': self.jobs_visited,
            'applications_submitted': self.applications_submitted,
            'applications_failed': self.applications_failed,
            'summary': {
                'total_searches': len(self.jobs_visited),
                'platforms_visited': len(set([j['platform'] for j in self.jobs_visited])),
                'successful_applications': len(self.applications_submitted),
                'failed_searches': len(self.applications_failed)
            }
        }

        filename = f"logs/job_automation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(filename, 'w') as f:
            json.dump(log_data, f, indent=2)

        logger.info(f"\n✓ Log saved: {filename}")
        return filename

    def run(self):
        """Main execution"""
        try:
            logger.info("\n" + "="*70)
            logger.info(" STARTING JOB APPLICATION AUTOMATION")
            logger.info("="*70 + "\n")

            # Generate URLs
            search_urls = self.generate_search_urls()

            if not search_urls:
                logger.error("No search URLs generated! Check config.json")
                return

            # Limit searches
            max_searches = self.automation_settings.get('max_searches_per_run', 25)
            if max_searches:
                search_urls = search_urls[:max_searches]

            logger.info(f"Will visit {len(search_urls)} job searches")
            logger.info(f"Max per run: {max_searches}")
            logger.info(f"Delay between searches: {self.automation_settings.get('delay_between_searches', 10)}s\n")

            # Visit each search
            for idx, search_info in enumerate(search_urls, 1):
                logger.info(f"\n[{idx}/{len(search_urls)}] Processing...")
                self.visit_job_search(search_info)

                # Delay between searches
                if idx < len(search_urls):
                    delay = self.automation_settings.get('delay_between_searches', 10)
                    logger.info(f"Waiting {delay} seconds before next search...\n")
                    time.sleep(delay)

            # Save results
            log_file = self.save_log()

            # Send email
            self.send_email_notification()

            # Final summary
            logger.info("\n" + "="*70)
            logger.info(" AUTOMATION COMPLETED")
            logger.info("="*70)
            logger.info(f"Total searches: {len(self.jobs_visited)}")
            logger.info(f"Platforms visited: {len(set([j['platform'] for j in self.jobs_visited]))}")
            logger.info(f"Successful applications: {len(self.applications_submitted)}")
            logger.info(f"Failed searches/errors: {len(self.applications_failed)}")
            logger.info(f"Log file: {log_file}")
            logger.info("="*70 + "\n")

        except KeyboardInterrupt:
            logger.info("\n\n*** INTERRUPTED BY USER ***")
            self.save_log()
        except Exception as e:
            logger.error(f"\n*** FATAL ERROR: {e} ***")
            import traceback
            logger.error(traceback.format_exc())
        finally:
            logger.info("\nClosing browser in 5 seconds...")
            time.sleep(5)
            self.driver.quit()
            logger.info("Browser closed. Automation ended.\n")


if __name__ == "__main__":
    try:
        bot = ComprehensiveJobAutoApply(config_file='config/config.json')
        bot.run()
    except Exception as e:
        logger.error(f"A fatal error occurred during bot execution: {e}")
        import traceback
        logger.error(traceback.format_exc())
