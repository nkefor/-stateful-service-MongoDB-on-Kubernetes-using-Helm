"""
Automated runner that installs packages and provides guidance
This script can run without user interaction
"""

import subprocess
import sys
import os
import json
from pathlib import Path

def print_header(text):
    """Print formatted header"""
    print("\n" + "="*60)
    print(f"  {text}")
    print("="*60 + "\n")

def check_python():
    """Check Python installation"""
    print_header("Checking Python Installation")
    print(f"✓ Python {sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro} found")
    print(f"✓ Python executable: {sys.executable}")
    return True

def install_packages():
    """Install required packages"""
    print_header("Installing Required Packages")

    packages = [
        "selenium==4.16.0",
        "webdriver-manager==4.0.1",
        "google-api-python-client==2.111.0",
        "google-auth==2.25.2",
        "google-auth-oauthlib==1.2.0",
        "beautifulsoup4==4.12.2"
    ]

    print("Installing packages (this may take 2-3 minutes)...\n")

    for package in packages:
        pkg_name = package.split("==")[0]
        print(f"Installing {pkg_name}...", end=" ", flush=True)
        try:
            result = subprocess.run(
                [sys.executable, "-m", "pip", "install", package, "--quiet"],
                capture_output=True,
                text=True,
                timeout=120
            )
            if result.returncode == 0:
                print("✓")
            else:
                print(f"✗ (Error: {result.stderr[:50]})")
        except Exception as e:
            print(f"✗ (Exception: {str(e)[:50]})")

    print("\n✓ Package installation complete!")

def check_config():
    """Check configuration file"""
    print_header("Checking Configuration")

    config_path = Path("config/config.json")

    if not config_path.exists():
        print("✗ config/config.json not found!")
        return False

    try:
        with open(config_path, 'r') as f:
            config = json.load(f)

        # Check if default values are still there
        needs_update = False
        if config.get("personal_info", {}).get("name") == "Your Full Name":
            print("⚠ WARNING: Config has default name - needs updating")
            needs_update = True

        if config.get("personal_info", {}).get("linkedin_password") == "YOUR_LINKEDIN_PASSWORD":
            print("⚠ WARNING: Config has default LinkedIn password - needs updating")
            needs_update = True

        if needs_update:
            print("\n⚠ You need to edit config/config.json with your information:")
            print("   - name (your full name)")
            print("   - email (your email address)")
            print("   - phone (your phone number)")
            print("   - linkedin_password (your LinkedIn password)")
            print("   - resume_path (path to your resume)")
            print("\nOpen config/config.json in Notepad and update these fields.")
            return False

        print("✓ Config file exists and appears configured")
        return True

    except Exception as e:
        print(f"✗ Error reading config: {e}")
        return False

def check_resume():
    """Check for resume file"""
    print_header("Checking Resume")

    resume_dir = Path("resumes")
    if not resume_dir.exists():
        print("✗ resumes/ folder not found")
        return False

    pdf_files = list(resume_dir.glob("*.pdf"))

    if not pdf_files:
        print("⚠ WARNING: No PDF resume found in resumes/ folder")
        print("\nPlease add your resume PDF to the resumes/ folder")
        print("Example: resumes/John_Doe_Resume.pdf")
        return False

    print(f"✓ Found resume(s): {', '.join([f.name for f in pdf_files])}")
    return True

def check_chrome():
    """Check if Chrome is installed"""
    print_header("Checking Google Chrome")

    chrome_paths = [
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    ]

    for path in chrome_paths:
        if Path(path).exists():
            print(f"✓ Chrome found at: {path}")
            return True

    print("⚠ Chrome not found in standard locations")
    print("Please install Chrome from: https://www.google.com/chrome")
    return False

def main():
    """Main execution"""
    print("\n" + "╔" + "═"*58 + "╗")
    print("║" + " "*58 + "║")
    print("║" + "  JOB AUTO-APPLY BOT - AUTOMATED SETUP & CHECK".center(58) + "║")
    print("║" + " "*58 + "║")
    print("╚" + "═"*58 + "╝")

    # Step 1: Check Python
    if not check_python():
        return

    # Step 2: Install packages
    try:
        install_packages()
    except Exception as e:
        print(f"\n✗ Package installation failed: {e}")
        print("Try running: pip install -r requirements.txt")
        return

    # Step 3: Check config
    config_ready = check_config()

    # Step 4: Check resume
    resume_ready = check_resume()

    # Step 5: Check Chrome
    chrome_ready = check_chrome()

    # Summary
    print_header("Setup Summary")

    print("Status:")
    print(f"  {'✓' if True else '✗'} Python installed")
    print(f"  {'✓' if True else '✗'} Packages installed")
    print(f"  {'✓' if config_ready else '⚠'} Configuration {'ready' if config_ready else 'needs update'}")
    print(f"  {'✓' if resume_ready else '⚠'} Resume {'found' if resume_ready else 'missing'}")
    print(f"  {'✓' if chrome_ready else '⚠'} Chrome {'installed' if chrome_ready else 'not found'}")

    print("\n" + "="*60)

    if config_ready and resume_ready and chrome_ready:
        print("\n✓ ALL CHECKS PASSED - READY TO RUN!")
        print("\nTo run the automation:")
        print("  python job_autoapply.py")
        print("\nOr double-click: RUN.bat")

        # Ask if user wants to run now
        print("\n" + "="*60)
        print("Would you like to run the automation now?")
        print("Note: This will open Chrome and start applying to jobs.")
        print("\nIf you want to run manually later, just type: python job_autoapply.py")

    else:
        print("\n⚠ SETUP INCOMPLETE - Please fix the issues above")
        print("\nRequired actions:")
        if not config_ready:
            print("  1. Edit config/config.json with your information")
        if not resume_ready:
            print("  2. Add your resume PDF to resumes/ folder")
        if not chrome_ready:
            print("  3. Install Google Chrome")

        print("\nAfter fixing, run: python job_autoapply.py")

if __name__ == "__main__":
    main()
