"""
Email Automation Script with Enhanced Security and Error Handling

This script sends automated email reports using Gmail SMTP.
Credentials are managed through environment variables for security.
"""

import smtplib
import logging
import os
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from typing import Optional, List
import datetime
from dotenv import load_dotenv
import time

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('email_automation.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class EmailAutomation:
    """
    A class to handle automated email sending with Gmail SMTP.

    Note: Gmail requires App Passwords instead of regular passwords.
    To generate an App Password:
    1. Enable 2-Step Verification on your Google Account
    2. Go to https://myaccount.google.com/apppasswords
    3. Generate an App Password for "Mail"
    4. Use that 16-character password in your .env file
    """

    def __init__(
        self,
        sender_email: Optional[str] = None,
        sender_password: Optional[str] = None,
        smtp_server: str = "smtp.gmail.com",
        smtp_port: int = 587,
        max_retries: int = 3
    ):
        """
        Initialize the EmailAutomation instance.

        Args:
            sender_email: Sender's email address (defaults to env variable)
            sender_password: Sender's password (defaults to env variable)
            smtp_server: SMTP server address
            smtp_port: SMTP port (587 for TLS, 465 for SSL)
            max_retries: Maximum number of retry attempts for failed sends
        """
        self.sender_email = sender_email or os.getenv('SENDER_EMAIL')
        self.sender_password = sender_password or os.getenv('SENDER_PASSWORD')
        self.smtp_server = smtp_server
        self.smtp_port = smtp_port
        self.max_retries = max_retries

        # Validate credentials
        if not self.sender_email or not self.sender_password:
            raise ValueError(
                "Email credentials not provided. "
                "Set SENDER_EMAIL and SENDER_PASSWORD in .env file or pass as arguments."
            )

        logger.info("EmailAutomation initialized successfully")

    def validate_email(self, email: str) -> bool:
        """
        Basic email validation.

        Args:
            email: Email address to validate

        Returns:
            True if valid, False otherwise
        """
        if not email or '@' not in email:
            return False
        return True

    def send_email(
        self,
        recipient_email: str,
        subject: str,
        body: str,
        html_body: Optional[str] = None,
        cc: Optional[List[str]] = None,
        bcc: Optional[List[str]] = None,
        attachments: Optional[List[str]] = None
    ) -> bool:
        """
        Send an email with optional HTML content and attachments.

        Args:
            recipient_email: Recipient's email address
            subject: Email subject
            body: Plain text email body
            html_body: Optional HTML email body
            cc: Optional list of CC recipients
            bcc: Optional list of BCC recipients
            attachments: Optional list of file paths to attach

        Returns:
            True if email sent successfully, False otherwise
        """
        # Validate email addresses
        if not self.validate_email(recipient_email):
            logger.error(f"Invalid recipient email: {recipient_email}")
            return False

        for attempt in range(1, self.max_retries + 1):
            try:
                logger.info(f"Attempt {attempt} of {self.max_retries} to send email to {recipient_email}")

                # Create message
                msg = MIMEMultipart('alternative')
                msg['From'] = self.sender_email
                msg['To'] = recipient_email
                msg['Subject'] = subject

                # Add CC recipients
                if cc:
                    msg['Cc'] = ', '.join(cc)

                # Attach plain text body
                msg.attach(MIMEText(body, 'plain'))

                # Attach HTML body if provided
                if html_body:
                    msg.attach(MIMEText(html_body, 'html'))

                # Attach files if provided
                if attachments:
                    for file_path in attachments:
                        if os.path.exists(file_path):
                            self._attach_file(msg, file_path)
                        else:
                            logger.warning(f"Attachment not found: {file_path}")

                # Prepare recipient list
                recipients = [recipient_email]
                if cc:
                    recipients.extend(cc)
                if bcc:
                    recipients.extend(bcc)

                # Connect to server and send email
                with smtplib.SMTP(self.smtp_server, self.smtp_port, timeout=30) as server:
                    server.starttls()
                    server.login(self.sender_email, self.sender_password)
                    server.sendmail(self.sender_email, recipients, msg.as_string())

                logger.info(f"Email sent successfully to {recipient_email}")
                return True

            except smtplib.SMTPAuthenticationError as e:
                logger.error(f"Authentication failed: {str(e)}")
                logger.error("Note: Gmail requires App Passwords. See class docstring for setup instructions.")
                return False  # Don't retry on auth errors

            except smtplib.SMTPException as e:
                logger.error(f"SMTP error on attempt {attempt}: {str(e)}")
                if attempt < self.max_retries:
                    wait_time = 2 ** attempt  # Exponential backoff
                    logger.info(f"Retrying in {wait_time} seconds...")
                    time.sleep(wait_time)
                else:
                    logger.error("Max retries reached. Email not sent.")
                    return False

            except Exception as e:
                logger.error(f"Unexpected error on attempt {attempt}: {str(e)}")
                if attempt < self.max_retries:
                    time.sleep(2)
                else:
                    return False

        return False

    def _attach_file(self, msg: MIMEMultipart, file_path: str) -> None:
        """
        Attach a file to the email message.

        Args:
            msg: Email message object
            file_path: Path to file to attach
        """
        try:
            with open(file_path, 'rb') as attachment:
                part = MIMEBase('application', 'octet-stream')
                part.set_payload(attachment.read())

            encoders.encode_base64(part)
            part.add_header(
                'Content-Disposition',
                f'attachment; filename= {os.path.basename(file_path)}'
            )
            msg.attach(part)
            logger.info(f"Attached file: {file_path}")

        except Exception as e:
            logger.error(f"Failed to attach file {file_path}: {str(e)}")


def generate_report() -> tuple[str, str]:
    """
    Generate the content for the email report.

    Returns:
        Tuple of (plain_text_body, html_body)
    """
    today = datetime.date.today().strftime('%Y-%m-%d')

    # Plain text version
    plain_body = f"""Daily Report for {today}

=================================

System Status: Operational
Reports Generated: 5
Errors Encountered: 0

Summary:
--------
Here is the content of your daily report...

You can customize this section with your actual report data.

=================================
Generated automatically by Email Automation System
"""

    # HTML version
    html_body = f"""
    <html>
      <head>
        <style>
          body {{ font-family: Arial, sans-serif; line-height: 1.6; }}
          .header {{ background-color: #4CAF50; color: white; padding: 10px; text-align: center; }}
          .content {{ padding: 20px; }}
          .footer {{ background-color: #f1f1f1; padding: 10px; text-align: center; font-size: 12px; }}
          .stats {{ background-color: #f9f9f9; padding: 15px; border-left: 4px solid #4CAF50; }}
        </style>
      </head>
      <body>
        <div class="header">
          <h2>Daily Report for {today}</h2>
        </div>
        <div class="content">
          <div class="stats">
            <p><strong>System Status:</strong> Operational ✓</p>
            <p><strong>Reports Generated:</strong> 5</p>
            <p><strong>Errors Encountered:</strong> 0</p>
          </div>
          <h3>Summary</h3>
          <p>Here is the content of your daily report...</p>
          <p>You can customize this section with your actual report data.</p>
        </div>
        <div class="footer">
          <p>Generated automatically by Email Automation System</p>
        </div>
      </body>
    </html>
    """

    return plain_body, html_body


def main():
    """
    Main function to execute the email automation.
    """
    try:
        # Initialize email automation
        email_client = EmailAutomation()

        # Get recipient email from environment or use default
        recipient_email = os.getenv('RECIPIENT_EMAIL', 'recipient_email@gmail.com')

        # Generate email subject
        today = datetime.date.today().strftime('%Y-%m-%d')
        subject = f"Daily Report - {today}"

        # Generate report content
        plain_body, html_body = generate_report()

        # Send the email
        success = email_client.send_email(
            recipient_email=recipient_email,
            subject=subject,
            body=plain_body,
            html_body=html_body
        )

        if success:
            logger.info("Daily report email sent successfully!")
        else:
            logger.error("Failed to send daily report email.")

    except Exception as e:
        logger.error(f"Error in main execution: {str(e)}")
        raise


if __name__ == "__main__":
    main()
