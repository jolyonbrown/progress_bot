#!/bin/bash
# Script to install the cron job for the Presidential Term Progress Bot

echo "Installing cron job for Presidential Term Progress Bot..."

# Check if crontab_entry.txt exists
if [ ! -f crontab_entry.txt ]; then
    echo "Error: crontab_entry.txt not found!"
    exit 1
fi

# Get current crontab
crontab -l > current_crontab.txt 2>/dev/null || echo "" > current_crontab.txt

# Remove any existing progress_bot entries and related comments
grep -v "progress_bot" current_crontab.txt | grep -v "Presidential Term Progress Bot" | grep -v "Run at 15:01 and 17:01" | grep -v "Run at 17:00 and 23:00" > new_crontab.txt

# Append the new entries
cat crontab_entry.txt >> new_crontab.txt

# Ensure there's a newline at the end of the file
echo "" >> new_crontab.txt

# Install the new crontab
crontab new_crontab.txt
CRONTAB_RESULT=$?

# Clean up temporary files
rm current_crontab.txt new_crontab.txt

if [ $CRONTAB_RESULT -eq 0 ]; then
    echo "Cron job installed successfully!"
    echo "The bot will run at 17:00 and 23:00 every day."
    echo "Output will be logged to: $(pwd)/cron_output.log"
else
    echo "Failed to install cron job. Error code: $CRONTAB_RESULT"
    exit 1
fi 