#!/bin/bash
# Script to check the format of the .env file

if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    echo "Please create a .env file based on the .env.example template."
    exit 1
fi

echo "Checking .env file format..."

# Check for common formatting issues
grep -n "=" .env | while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    content=$(echo "$line" | cut -d: -f2-)
    
    # Check for spaces around equals sign
    if echo "$content" | grep -q " = "; then
        echo "Line $line_num: Warning - spaces around equals sign may cause issues: $content"
    fi
    
    # Check for quotes that might not be properly formatted
    if echo "$content" | grep -q '=".*"' || echo "$content" | grep -q "='.*'"; then
        echo "Line $line_num: Warning - quotes around value may cause issues: $content"
    fi
    
    # Check for empty values
    if echo "$content" | grep -q "=$"; then
        echo "Line $line_num: Warning - empty value: $content"
    fi
    
    # Check for commented out variables
    if echo "$content" | grep -q "^#.*="; then
        echo "Line $line_num: Info - commented out variable: $content"
    fi
done

echo ""
echo "Recommended .env format:"
echo "VARIABLE_NAME=value"
echo ""
echo "No spaces around equals sign, no quotes around values unless needed for special characters."
echo ""

# Test loading the variables
echo "Testing loading variables from .env..."
source .env

# Check if variables are set
echo "TWITTER_API_KEY set: $([ ! -z "$TWITTER_API_KEY" ] && echo "YES" || echo "NO")"
echo "TWITTER_API_SECRET set: $([ ! -z "$TWITTER_API_SECRET" ] && echo "YES" || echo "NO")"
echo "TWITTER_ACCESS_TOKEN set: $([ ! -z "$TWITTER_ACCESS_TOKEN" ] && echo "YES" || echo "NO")"
echo "TWITTER_ACCESS_SECRET set: $([ ! -z "$TWITTER_ACCESS_SECRET" ] && echo "YES" || echo "NO")"
echo "TWITTER_BEARER_TOKEN set: $([ ! -z "$TWITTER_BEARER_TOKEN" ] && echo "YES" || echo "NO")"

echo ""
echo "If all variables show as 'YES', your .env file format is correct."
echo "If any show as 'NO', check the format of that variable in your .env file." 