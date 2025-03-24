#!/bin/bash

# Check if XcodeGen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen is not installed. Installing..."
    brew install xcodegen
fi

echo "Generating Xcode project from project.yml..."
xcodegen generate

echo "Project generation complete!"
echo "You can now open Playdates.xcodeproj in Xcode."
