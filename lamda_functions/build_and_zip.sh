#!/bin/bash
set -e
cd "$(dirname "$0")"
zip -j process_flights_data.zip process_flights_data.py
zip -j generate_daily_report.zip generate_daily_report.py
mv *.zip ..
cd ..
echo "Zips created in project root"

