"""
Enhanced Job Auto-Application Script
Supports 20+ job platforms with comprehensive automation
"""

import os
import time
import json
import logging
from datetime import datetime
from typing import List, Dict

# Import secure config loader (no external dependencies)
try:
    from simple_config_loader import load_config, print_config_summary
except ImportError:
    from config_loader import load_config
    print_config_summary = None

# Selenium imports
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import TimeoutException, NoSuchElementException

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


class EnhancedJobAutoApply:
    """Enhanced job application automation supporting 20+ platforms"""

    # Platform URLs
    PLATFORM_URLS = {
        'dice': 'https://www.dice.com',
        'indeed': 'https://www.indeed.com',
        'ziprecruiter': 'https://www.ziprecruiter.com',
        'monster': 'https://www.monster.com',
        'glassdoor': 'https://www.glassdoor.com',
        'careerbuilder': 'https://www.careerbuilder.com',
        'linkedin': 'https://www.linkedin.com',
        'builtin': 'https://builtin.com',
        'jobright_ai': 'https://jobright.ai',
        'remote_co': 'https://remote.co',
        'flexjobs': 'https://www.flexjobs.com',
        'wellfound': 'https://wellfound.com',
        'weworkremotely': 'https://weworkremotely.com',
        'remotive': 'https://remotive.io',
        'letsworkremotely': 'https://letsworkremotely.com',
        'toptal': 'https://www.toptal.com',
        'hired': 'https://hired.com',
        'angellist': 'https://angel.co',
        'theladders': 'https://www.theladders.com',
        'zapier': 'https://zapier.com/jobs',
        'flexa': 'https://flexa.careers',
        'nodesk': 'https://nodesk.co',
        'dynamitejobs': 'https://dynamitejobs.com'
    }

    def __init__(self, config_file: str = 'config/config.json'):
        """Initialize enhanced automation bot"""
        logger.info("Initializing Enhanced Job Auto-Apply Bot")

        # Load configuration securely
        self.config = load_config(config_file)

        # Validate required fields
        required_fields = [
            ('personal_info', 'name'),
            ('personal_info', 'email'),
            ('personal_info', 'linkedin_email'),
            ('personal_info', 'linkedin_password')
        ]

        errors = []
        for section, field in required_fields:
            value = self.config.get(section, {}).get(field)
            if not value or value.startswith('${'):
                errors.append(f"Missing or unset: {section}.{field}")

        if errors:
            logger.error("Configuration validation failed:")
            for error in errors:
                logger.error(f"  - {error}")
            raise ValueError("Invalid configuration. Check your .env file.")

        self.personal_info = self.config['personal_info']
        self.job_preferences = self.config['job_preferences']
        self.platforms = self.config.get('platforms', {})

        # Print configuration summary
        if print_config_summary:
            print_config_summary(self.config)

        # Setup Selenium
        self.driver = self._setup_selenium()

        # Application tracking
        self.applications_submitted = []
        self.applications_failed = []

        logger.info("Enhanced Job Auto-Apply Bot initialized successfully")

    def _setup_selenium(self) -> webdriver.Chrome:
        """Set up Selenium WebDriver"""
        chrome_options = Options()

        # Use dedicated automation profile
        automation_profile = os.path.join(os.getcwd(), 'chrome_automation_profile')
        os.makedirs(automation_profile, exist_ok=True)
        chrome_options.add_argument(f'--user-data-dir={automation_profile}')
        chrome_options.add_argument('--profile-directory=Default')

        logger.info("Using dedicated Chrome profile for automation")
        logger.info("You have 120 seconds to log in at each platform if needed")

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

        prefs = {
            "download.default_directory": os.path.join(os.getcwd(), "downloads"),
            "download.prompt_for_download": False,
        }
        chrome_options.add_experimental_option("prefs", prefs)

        local_chromedriver = os.path.join(os.getcwd(), 'chromedriver-win64', 'chromedriver.exe')
        if os.path.exists(local_chromedriver):
            service = Service(local_chromedriver)
            logger.info(f"Using local chromedriver: {local_chromedriver}")
        else:
            from webdriver_manager.chrome import ChromeDriverManager
            service = Service(ChromeDriverManager().install())

        driver = webdriver.Chrome(service=service, options=chrome_options)
        driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")

        return driver

    def apply_to_platform(self, platform_name: str):
        """Generic method to apply to jobs on any platform"""
        if not self.platforms.get(platform_name, False):
            logger.info(f"Platform {platform_name} is disabled in config")
            return

        logger.info(f"Starting {platform_name.upper()} job applications")

        try:
            platform_url = self.PLATFORM_URLS.get(platform_name)
            if not platform_url:
                logger.warning(f"No URL configured for {platform_name}")
                return

            self.driver.get(platform_url)
            time.sleep(5)

            # Give user time to log in if needed
            logger.info(f"If you need to log into {platform_name}, please do so now")
            logger.info("Waiting 120 seconds for manual login if needed...")
            time.sleep(120)

            # Search for jobs on this platform
            for job_title in self.job_preferences['job_titles']:
                for location in self.job_preferences['locations']:
                    self._search_platform_jobs(platform_name, job_title, location)

        except Exception as e:
            logger.error(f"Error on {platform_name}: {e}")

    def _search_platform_jobs(self, platform: str, job_title: str, location: str):
        """Search for jobs on a specific platform"""
        logger.info(f"Searching {platform}: {job_title} in {location}")

        try:
            # Platform-specific search logic
            if platform == 'dice':
                self._search_dice(job_title, location)
            elif platform == 'glassdoor':
                self._search_glassdoor(job_title, location)
            elif platform == 'monster':
                self._search_monster(job_title, location)
            elif platform == 'careerbuilder':
                self._search_careerbuilder(job_title, location)
            elif platform == 'builtin':
                self._search_builtin(job_title, location)
            elif platform == 'weworkremotely':
                self._search_weworkremotely(job_title, location)
            elif platform == 'remotive':
                self._search_remotive(job_title, location)
            elif platform == 'wellfound':
                self._search_wellfound(job_title, location)
            else:
                logger.info(f"Search not yet implemented for {platform}")

        except Exception as e:
            logger.error(f"Error searching {platform} for {job_title} in {location}: {e}")

    def _search_dice(self, job_title: str, location: str):
        """Search Dice.com"""
        try:
            self.driver.get('https://www.dice.com/jobs')
            time.sleep(3)

            # Fill search form
            job_field = self.driver.find_element(By.ID, 'typeaheadInput')
            job_field.clear()
            job_field.send_keys(job_title)

            location_field = self.driver.find_element(By.ID, 'google-location-search')
            location_field.clear()
            location_field.send_keys(location)
            location_field.send_keys(Keys.RETURN)

            time.sleep(3)
            logger.info(f"Searched Dice for {job_title} in {location}")

        except Exception as e:
            logger.error(f"Error searching Dice: {e}")

    def _search_glassdoor(self, job_title: str, location: str):
        """Search Glassdoor"""
        try:
            search_url = f"https://www.glassdoor.com/Job/jobs.htm?sc.keyword={job_title.replace(' ', '+')}&locT=C&locId=1147401"
            self.driver.get(search_url)
            time.sleep(3)
            logger.info(f"Searched Glassdoor for {job_title}")

        except Exception as e:
            logger.error(f"Error searching Glassdoor: {e}")

    def _search_monster(self, job_title: str, location: str):
        """Search Monster.com"""
        try:
            self.driver.get('https://www.monster.com')
            time.sleep(3)

            job_field = self.driver.find_element(By.ID, 'q')
            job_field.clear()
            job_field.send_keys(job_title)

            location_field = self.driver.find_element(By.ID, 'where')
            location_field.clear()
            location_field.send_keys(location)
            location_field.send_keys(Keys.RETURN)

            time.sleep(3)
            logger.info(f"Searched Monster for {job_title} in {location}")

        except Exception as e:
            logger.error(f"Error searching Monster: {e}")

    def _search_careerbuilder(self, job_title: str, location: str):
        """Search CareerBuilder"""
        try:
            search_url = f"https://www.careerbuilder.com/jobs?keywords={job_title.replace(' ', '+')}&location={location.replace(' ', '+')}"
            self.driver.get(search_url)
            time.sleep(3)
            logger.info(f"Searched CareerBuilder for {job_title} in {location}")

        except Exception as e:
            logger.error(f"Error searching CareerBuilder: {e}")

    def _search_builtin(self, job_title: str, location: str):
        """Search BuiltIn"""
        try:
            self.driver.get('https://builtin.com/jobs')
            time.sleep(3)

            job_field = self.driver.find_element(By.NAME, 'search')
            job_field.clear()
            job_field.send_keys(job_title)
            job_field.send_keys(Keys.RETURN)

            time.sleep(3)
            logger.info(f"Searched BuiltIn for {job_title}")

        except Exception as e:
            logger.error(f"Error searching BuiltIn: {e}")

    def _search_weworkremotely(self, job_title: str, location: str):
        """Search WeWorkRemotely"""
        try:
            self.driver.get('https://weworkremotely.com/remote-jobs/search?term=' + job_title.replace(' ', '+'))
            time.sleep(3)
            logger.info(f"Searched WeWorkRemotely for {job_title}")

        except Exception as e:
            logger.error(f"Error searching WeWorkRemotely: {e}")

    def _search_remotive(self, job_title: str, location: str):
        """Search Remotive.io"""
        try:
            self.driver.get('https://remotive.io/remote-jobs/software-dev')
            time.sleep(3)
            logger.info(f"Browsing Remotive remote jobs")

        except Exception as e:
            logger.error(f"Error searching Remotive: {e}")

    def _search_wellfound(self, job_title: str, location: str):
        """Search Wellfound (formerly AngelList)"""
        try:
            self.driver.get('https://wellfound.com/jobs')
            time.sleep(3)

            search_field = self.driver.find_element(By.CSS_SELECTOR, 'input[placeholder*="Search"]')
            search_field.clear()
            search_field.send_keys(job_title)
            search_field.send_keys(Keys.RETURN)

            time.sleep(3)
            logger.info(f"Searched Wellfound for {job_title}")

        except Exception as e:
            logger.error(f"Error searching Wellfound: {e}")

    def save_application_log(self):
        """Save application log to JSON"""
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

            # Log all enabled platforms
            enabled_platforms = [name for name, enabled in self.platforms.items() if enabled]
            logger.info(f"Starting {', '.join(enabled_platforms)} job applications")

            # Log all locations being searched
            locations_str = ', '.join(self.job_preferences['locations'])
            logger.info(f"Searching locations: {locations_str}")

            # Apply to each enabled platform
            for platform_name, enabled in self.platforms.items():
                if enabled:
                    self.apply_to_platform(platform_name)

            # Save results
            self.save_application_log()

            logger.info("Job application automation completed")
            logger.info(f"Total applications submitted: {len(self.applications_submitted)}")

        except Exception as e:
            logger.error(f"Fatal error in automation: {e}")

        finally:
            self.driver.quit()
            logger.info("Browser closed")


if __name__ == "__main__":
    bot = EnhancedJobAutoApply(config_file='config/config.json')
    bot.run()
