"""
COPA Complaint Data Download via Socrata API
Proj: COPA Eval
Author: Michelle Shames

Description: Retrieve civilian complaint data from Chicago Data Portal via their open data API.
"""

## SETUP
import requests
import pandas as pd
import os
os.makedirs("data/API/raw", exist_ok=True)

## CONFIG
base_url = "https://data.cityofchicago.org/resource/mft5-nfa8.json"
params = {
    "$where": "complaint_date between '2013-01-01T00:00:00' and '2022-12-31T23:59:59'",
    "$limit": 100000
}

## FETCH DATA
print("Fetching COPA cases data...")
response = requests.get(base_url, params=params)
print(f"Status code: {response.status_code}")

## PROCESS DATA
if response.status_code == 200:
    df = pd.DataFrame(response.json())
    df.to_csv("data/API/raw/copa_cases.csv", index=False)
    print(f"Downloaded {len(df)} records ({df.shape[1]} columns)")
else:
    print(f"Error: {response.status_code}: {response.text}")
