"""
Sample COPA Complaint Data Download using API

Proj: COPA Eval
Author: Michelle Shames

Description: Retrieve civilian complaint data from Chicago Data Portal via their open data API.
"""

## SETUP
import requests
import pandas as pd

## CONFIG
url = "https://data.cityofchicago.org/resource/mft5-nfa8.json"


## FETCH DATA
print("Fetching COPA cases data...")
response = requests.get(url)
print(f"Status code: {response.status_code}")

## PROCESS DATA
if response.status_code == 200:
    # Convert to DataFrame
    data = response.json()
    df = pd.DataFrame(data)
    
    # Save to CSV
    df.to_csv("copa_cases.csv", index=False)
    
       # Display results
    print(f"✓ Successfully downloaded {len(df)} records")
    print(f"✓ Saved to copa_cases.csv")
    print(f"\nDataset shape: {df.shape[0]} rows, {df.shape[1]} columns")
    print("\nColumn names:")
    print(df.columns.tolist())
    print("\nFirst few rows:")
    print(df.head())
else:
    print(f"✗ Error: {response.status_code}")
    print(f"Response: {response.text}")
