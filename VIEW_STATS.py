#!/usr/bin/env python3
"""
View Job Automation Statistics
Displays data from the SQLite database
"""

import sqlite3
import sys
from datetime import datetime

DB_PATH = 'jobautomation/logs/job_applications.db'

def view_stats():
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        print("=" * 70)
        print(" JOB AUTOMATION STATISTICS")
        print("=" * 70)
        print()
        
        # Total applications
        cursor.execute('SELECT COUNT(*) FROM applications')
        total = cursor.fetchone()[0]
        print(f"Total Applications: {total}")
        
        # By platform
        cursor.execute('''
            SELECT platform_name, COUNT(*) 
            FROM applications 
            GROUP BY platform_name 
            ORDER BY COUNT(*) DESC
        ''')
        platforms = cursor.fetchall()
        print(f"\nBy Platform:")
        for platform, count in platforms:
            print(f"  {platform}: {count}")
        
        # By status
        cursor.execute('''
            SELECT status, COUNT(*) 
            FROM applications 
            GROUP BY status
        ''')
        statuses = cursor.fetchall()
        print(f"\nBy Status:")
        for status, count in statuses:
            print(f"  {status}: {count}")
        
        # Recent applications
        cursor.execute('''
            SELECT platform_name, job_title, location, timestamp
            FROM applications
            ORDER BY created_at DESC
            LIMIT 10
        ''')
        recent = cursor.fetchall()
        print(f"\nMost Recent Applications:")
        for platform, title, location, timestamp in recent:
            print(f"  {platform}: {title} in {location}")
            print(f"    Time: {timestamp}")
        
        # Sessions
        cursor.execute('SELECT COUNT(DISTINCT session_id) FROM applications')
        sessions = cursor.fetchone()[0]
        print(f"\nTotal Sessions: {sessions}")
        
        print()
        print("=" * 70)
        
        conn.close()
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    view_stats()
