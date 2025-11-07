"""
Configuration Loader for Job Automation
Securely loads configuration from environment variables and JSON template
"""

import os
import json
import re
from pathlib import Path
from dotenv import load_dotenv


class ConfigLoader:
    """Loads configuration with environment variable substitution"""

    def __init__(self, config_path="config/config.json", env_file=".env"):
        """
        Initialize configuration loader

        Args:
            config_path: Path to config JSON file (relative to script location)
            env_file: Path to .env file (relative to script location)
        """
        self.script_dir = Path(__file__).parent
        self.config_path = self.script_dir / config_path
        self.env_file = self.script_dir / env_file

        # Load environment variables
        self._load_env()

        # Load and parse configuration
        self.config = self._load_config()

    def _load_env(self):
        """Load environment variables from .env file"""
        if not self.env_file.exists():
            raise FileNotFoundError(
                f"Environment file not found: {self.env_file}\n"
                f"Please copy .env.example to .env and fill in your credentials."
            )

        load_dotenv(self.env_file)
        print(f"✓ Loaded environment variables from {self.env_file}")

    def _load_config(self):
        """Load configuration from JSON file with env var substitution"""
        if not self.config_path.exists():
            raise FileNotFoundError(
                f"Configuration file not found: {self.config_path}"
            )

        with open(self.config_path, 'r', encoding='utf-8') as f:
            config_text = f.read()

        # Substitute environment variables
        config_text = self._substitute_env_vars(config_text)

        # Parse JSON
        config = json.loads(config_text)
        print(f"✓ Loaded configuration from {self.config_path}")

        return config

    def _substitute_env_vars(self, text):
        """
        Replace ${VAR_NAME} with environment variable values

        Args:
            text: String containing ${VAR_NAME} placeholders

        Returns:
            String with substituted values
        """
        # Find all ${VAR_NAME} patterns
        pattern = r'\$\{([^}]+)\}'

        def replace_var(match):
            var_name = match.group(1)
            value = os.getenv(var_name)

            if value is None:
                raise ValueError(
                    f"Environment variable '{var_name}' not found in .env file.\n"
                    f"Please add it to {self.env_file}"
                )

            # Return JSON-safe value (add quotes for strings, not for numbers/booleans)
            if value.lower() in ('true', 'false'):
                return value.lower()
            elif value.isdigit():
                return value
            else:
                # Escape quotes in string values
                return f'"{value}"'

        return re.sub(pattern, replace_var, text)

    def get(self, *keys, default=None):
        """
        Get nested configuration value

        Args:
            *keys: Keys to traverse (e.g., 'personal_info', 'name')
            default: Default value if key not found

        Returns:
            Configuration value or default

        Example:
            config.get('personal_info', 'name')  # Returns name from config
            config.get('automation_settings', 'max_applications_per_run')
        """
        value = self.config
        for key in keys:
            if isinstance(value, dict):
                value = value.get(key)
                if value is None:
                    return default
            else:
                return default
        return value

    def get_all(self):
        """Get entire configuration dictionary"""
        return self.config

    def validate(self):
        """
        Validate that all required configuration is present

        Returns:
            tuple: (bool, list of errors)
        """
        errors = []

        # Check required sections
        required_sections = ['personal_info', 'job_preferences', 'platforms',
                           'automation_settings', 'filters']

        for section in required_sections:
            if section not in self.config:
                errors.append(f"Missing required section: {section}")

        # Check required personal_info fields
        if 'personal_info' in self.config:
            required_personal = ['name', 'email', 'linkedin_email', 'linkedin_password']
            for field in required_personal:
                value = self.config['personal_info'].get(field)
                if not value or value.startswith('${'):
                    errors.append(f"Missing or unset: personal_info.{field}")

        # Check for placeholder values
        config_str = json.dumps(self.config)
        if '${' in config_str:
            errors.append("Configuration contains unsubstituted variables (check .env file)")

        return (len(errors) == 0, errors)

    def print_summary(self):
        """Print configuration summary (without sensitive data)"""
        print("\n" + "="*60)
        print("JOB AUTOMATION CONFIGURATION SUMMARY")
        print("="*60)

        # Personal info (sanitized)
        name = self.get('personal_info', 'name', default='Not set')
        email = self.get('personal_info', 'email', default='Not set')
        print(f"\n👤 Personal Info:")
        print(f"   Name: {name}")
        print(f"   Email: {email}")
        print(f"   LinkedIn: {'✓ Configured' if self.get('personal_info', 'linkedin_password') else '✗ Not set'}")

        # Job preferences
        print(f"\n💼 Job Preferences:")
        titles = self.get('job_preferences', 'job_titles', default=[])
        print(f"   Titles: {len(titles)} job titles configured")
        locations = self.get('job_preferences', 'locations', default=[])
        print(f"   Locations: {len(locations)} locations")
        print(f"   Salary Min: ${self.get('job_preferences', 'salary_min', default=0):,}")

        # Platforms
        print(f"\n🌐 Platforms:")
        platforms = self.get('platforms', default={})
        enabled = [p for p, enabled in platforms.items() if enabled]
        print(f"   Enabled: {len(enabled)} platforms")
        print(f"   {', '.join(enabled[:5])}{'...' if len(enabled) > 5 else ''}")

        # Automation settings
        print(f"\n⚙️  Automation Settings:")
        print(f"   Max applications/run: {self.get('automation_settings', 'max_applications_per_run')}")
        print(f"   Delay: {self.get('automation_settings', 'delay_between_applications')}s")
        print(f"   Headless: {self.get('automation_settings', 'headless_browser')}")

        print("\n" + "="*60 + "\n")


def load_config():
    """
    Convenience function to load configuration

    Returns:
        ConfigLoader instance
    """
    return ConfigLoader()


# Example usage
if __name__ == "__main__":
    try:
        # Load configuration
        config = load_config()

        # Validate
        is_valid, errors = config.validate()
        if not is_valid:
            print("❌ Configuration validation failed:")
            for error in errors:
                print(f"   - {error}")
            exit(1)

        print("✓ Configuration validated successfully")

        # Print summary
        config.print_summary()

        # Example: Access specific values
        print("Example usage:")
        print(f"  Name: {config.get('personal_info', 'name')}")
        print(f"  Max apps: {config.get('automation_settings', 'max_applications_per_run')}")

    except Exception as e:
        print(f"❌ Error loading configuration: {e}")
        exit(1)
