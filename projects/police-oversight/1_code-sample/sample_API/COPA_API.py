"""
Sample COPA Complaint Data Download using API

Proj: COPA Eval
Author: Michelle Shames
"""

import requests
import pandas as pd

# API endpoint for COPA cases
url = "https://data.cityofchicago.org/resource/mft5-nfa8.json"

print("Fetching COPA cases data...")

# Make simple API request with no parameters first
response = requests.get(url)

print(f"Status code: {response.status_code}")

# Check if request was successful
if response.status_code == 200:
    # Convert to DataFrame
    data = response.json()
    df = pd.DataFrame(data)
    
    # Save to CSV
    df.to_csv("copa_cases.csv", index=False)
    
    print(f"✓ Successfully downloaded {len(df)} records")
    print("✓ Saved to copa_cases.csv")
    print("\nFirst few rows:")
    print(df.head())
else:
    print(f"✗ Error: {response.status_code}")
    print(f"Response: {response.text}")