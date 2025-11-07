"""
Simple Configuration Loader (No External Dependencies)
Loads .env file and substitutes variables in config.json
"""

import os
import json
import re
from pathlib import Path


def load_env_file(env_path=".env"):
    """Load environment variables from .env file without python-dotenv"""
    env_vars = {}

    if not os.path.exists(env_path):
        raise FileNotFoundError(
            f"Environment file not found: {env_path}\n"
            f"Please copy .env.example to .env and fill in your credentials."
        )

    with open(env_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()

            # Skip comments and empty lines
            if not line or line.startswith('#'):
                continue

            # Parse KEY=VALUE
            if '=' in line:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip()

                # Remove quotes if present
                if value.startswith('"') and value.endswith('"'):
                    value = value[1:-1]
                elif value.startswith("'") and value.endswith("'"):
                    value = value[1:-1]

                env_vars[key] = value

    print(f"[OK] Loaded {len(env_vars)} environment variables from {env_path}")
    return env_vars


def substitute_env_vars(text, env_vars):
    """Replace ${VAR_NAME} with environment variable values"""
    # Pattern to match "${VAR_NAME}" (with quotes) or ${VAR_NAME} (without)
    pattern = r'"?\$\{([^}]+)\}"?'

    def replace_var(match):
        var_name = match.group(1)
        value = env_vars.get(var_name)

        if value is None:
            raise ValueError(
                f"Environment variable '{var_name}' not found in .env file.\n"
                f"Please add it to .env"
            )

        # Check if pattern had quotes (by checking what was matched)
        matched_text = match.group(0)
        has_quotes = matched_text.startswith('"')

        # Return JSON-safe value
        if value.lower() in ('true', 'false'):
            return value.lower()
        elif value.isdigit():
            return value
        else:
            # Escape quotes in string values
            value = value.replace('"', '\\"')
            # Only add quotes if original didn't have them
            if has_quotes:
                return f'"{value}"'
            else:
                return value

    return re.sub(pattern, replace_var, text)


def load_config(config_path="config/config.json", env_file=".env"):
    """
    Load configuration with environment variable substitution

    Args:
        config_path: Path to config JSON file
        env_file: Path to .env file

    Returns:
        dict: Configuration dictionary with substituted values
    """
    # Load environment variables
    env_vars = load_env_file(env_file)

    # Load config file
    if not os.path.exists(config_path):
        raise FileNotFoundError(f"Configuration file not found: {config_path}")

    with open(config_path, 'r', encoding='utf-8') as f:
        config_text = f.read()

    # Substitute environment variables
    config_text = substitute_env_vars(config_text, env_vars)

    # Parse JSON
    config = json.loads(config_text)
    print(f"[OK] Loaded configuration from {config_path}")

    return config


def print_config_summary(config):
    """Print configuration summary (without sensitive data)"""
    print("\n" + "="*60)
    print("JOB AUTOMATION CONFIGURATION SUMMARY")
    print("="*60)

    # Personal info (sanitized)
    name = config.get('personal_info', {}).get('name', 'Not set')
    email = config.get('personal_info', {}).get('email', 'Not set')
    print(f"\n[PERSON] Personal Info:")
    print(f"   Name: {name}")
    print(f"   Email: {email}")
    has_pwd = bool(config.get('personal_info', {}).get('linkedin_password'))
    print(f"   LinkedIn: {'[OK] Configured' if has_pwd else '[X] Not set'}")

    # Job preferences
    print(f"\n[BRIEFCASE] Job Preferences:")
    titles = config.get('job_preferences', {}).get('job_titles', [])
    print(f"   Titles: {len(titles)} job titles configured")
    if titles:
        print(f"   - {', '.join(titles[:3])}{'...' if len(titles) > 3 else ''}")

    locations = config.get('job_preferences', {}).get('locations', [])
    print(f"   Locations: {len(locations)} locations")
    if locations:
        print(f"   - {', '.join(locations[:5])}{'...' if len(locations) > 5 else ''}")

    salary_min = config.get('job_preferences', {}).get('salary_min', 0)
    print(f"   Salary Min: ${salary_min:,}")

    # Platforms
    print(f"\n[GLOBE] Platforms:")
    platforms = config.get('platforms', {})
    enabled = [p for p, is_enabled in platforms.items() if is_enabled]
    print(f"   Enabled: {len(enabled)} platforms")
    if enabled:
        print(f"   - {', '.join(enabled[:5])}{'...' if len(enabled) > 5 else ''}")

    # Automation settings
    print(f"\n[SETTINGS]  Automation Settings:")
    auto_settings = config.get('automation_settings', {})
    print(f"   Max applications/run: {auto_settings.get('max_applications_per_run', 'N/A')}")
    print(f"   Delay: {auto_settings.get('delay_between_applications', 'N/A')}s")
    print(f"   Headless: {auto_settings.get('headless_browser', 'N/A')}")

    print("\n" + "="*60 + "\n")


# Test/Example usage
if __name__ == "__main__":
    try:
        print("Testing Simple Configuration Loader")
        print("="*60)

        # Load configuration
        config = load_config()

        # Print summary
        print_config_summary(config)

        # Validate required fields
        required_fields = [
            ('personal_info', 'name'),
            ('personal_info', 'email'),
            ('personal_info', 'linkedin_email'),
            ('personal_info', 'linkedin_password')
        ]

        print("Validating configuration...")
        errors = []
        for section, field in required_fields:
            value = config.get(section, {}).get(field)
            if not value or value.startswith('${'):
                errors.append(f"Missing or unset: {section}.{field}")

        if errors:
            print("\n[ERROR] Configuration validation failed:")
            for error in errors:
                print(f"   - {error}")
            exit(1)

        print("[OK] Configuration validated successfully\n")
        print("Ready to run job automation!")

    except Exception as e:
        print(f"\n[ERROR] Error: {e}")
        exit(1)
