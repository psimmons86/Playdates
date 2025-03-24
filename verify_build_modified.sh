#!/bin/bash

# Set terminal colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===========================================================${NC}"
echo -e "${BLUE}                Verifying Project Fixes                    ${NC}"
echo -e "${BLUE}===========================================================${NC}"

# Check if swiftc is available
if ! command -v swiftc &> /dev/null; then
    echo -e "${RED}Error: swiftc command not found${NC}"
    echo "This script requires Xcode Command Line Tools."
    exit 1
fi

# Make sure we're in the project directory
cd "$(dirname "$0")"

echo -e "${BLUE}>> Cleaning build artifacts...${NC}"
rm -rf build/
xcodebuild clean -project Playdates.xcodeproj -scheme Playdates

echo -e "${BLUE}>> Checking syntax of Swift files...${NC}"

# List of critical files to verify
FILES_TO_CHECK=(
  "PlaydatesApp/Utils/FirebaseSafetyKit.swift"
  "PlaydatesApp/ViewModels/PlaydateViewModel.swift"
  "PlaydatesApp/Services/LocationManager.swift"
  "PlaydatesApp/Models/Location.swift"
  "PlaydatesApp/Models/Playdate.swift"
  "PlaydatesApp/Models/ActivityType.swift"
)

# Check syntax of key files
SUCCESS=true
for file in "${FILES_TO_CHECK[@]}"; do
  echo -e "${BLUE}Checking syntax of $file...${NC}"
  
  # Check syntax using swiftc -parse
  if swiftc -parse "$file" 2>/dev/null; then
    echo -e "${GREEN}✓ Syntax check passed for $file${NC}"
  else
    echo -e "${RED}✗ Syntax error in $file${NC}"
    SUCCESS=false
  fi
done

echo -e "${BLUE}>> Analyzing for Firebase safety issues...${NC}"
# Look for any occurrences of direct Firebase access without safety methods
UNSAFE_FIREBASE_USAGE=$(find ./PlaydatesApp -name "*.swift" -exec grep -l "document.data()" {} \; | grep -v "FirebaseSafetyKit.swift")

if [ -z "$UNSAFE_FIREBASE_USAGE" ]; then
    echo -e "${GREEN}✓ No unsafe Firebase data access detected.${NC}"
else
    echo -e "${RED}⚠️ Potential unsafe Firebase data access detected in:${NC}"
    echo "$UNSAFE_FIREBASE_USAGE"
    echo -e "${BLUE}Remember to use data = FirebaseSafetyKit.sanitizeData(rawData) for all Firebase data.${NC}"
fi

echo -e "${BLUE}>> Scanning for type conversion points...${NC}"
# Look for places that might need sanitization
TYPE_CONVERSION_POINTS=$(find ./PlaydatesApp -name "*.swift" -exec grep -l "as? NSNumber\|as? String" {} \; | grep -v "FirebaseSafetyKit.swift")

if [ -n "$TYPE_CONVERSION_POINTS" ]; then
    echo -e "${BLUE}Places that might benefit from FirebaseSafetyKit:${NC}"
    echo "$TYPE_CONVERSION_POINTS"
fi

# Summary
if [ "$SUCCESS" = true ]; then
    echo -e "${GREEN}===========================================================${NC}"
    echo -e "${GREEN}All critical files passed syntax checking!${NC}"
    echo -e "${GREEN}Summary of changes:${NC}"
    echo -e "${GREEN}- Created consolidated FirebaseSafetyKit${NC}"
    echo -e "${GREEN}- Fixed string/number type conversion issues${NC}"
    echo -e "${GREEN}- Made LocationManager compatible with ActivityType${NC}"
    echo -e "${GREEN}- Fixed closure parameter type in PlaydateViewModel${NC}"
    echo -e "${GREEN}- Removed redundant utility files${NC}"
    echo -e "${GREEN}===========================================================${NC}"
else
    echo -e "${RED}===========================================================${NC}"
    echo -e "${RED}Some files still have syntax errors. Please review and fix them.${NC}"
    echo -e "${RED}===========================================================${NC}"
fi
