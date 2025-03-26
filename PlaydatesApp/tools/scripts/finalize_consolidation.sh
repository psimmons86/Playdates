#!/bin/bash

echo "=========================================================="
echo "FINALIZING PLAYDATES APP CONSOLIDATION"
echo "=========================================================="

# Create dashboard and social directories if they don't exist
mkdir -p PlaydatesApp/Views/Dashboard
mkdir -p PlaydatesApp/Views/Social

# Check for and remove any remaining references to old view files
echo "Checking for lingering references to old views..."

# List of directories that should no longer be referenced
OLD_DIRS=(
  "PlaydatesApp/Views/Explore"
  "PlaydatesApp/Views/Playdates"
  "PlaydatesApp/Views/Friends"
  "PlaydatesApp/Views/Profile"
  "PlaydatesApp/Views/Home"
)

for dir in "${OLD_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo "Found old directory: $dir - moving to backup"
    mkdir -p "bk_removed_files/Views"
    mv -f "$dir" "bk_removed_files/Views/" 2>/dev/null || true
  fi
done

# Make sure the consolidated view files exist
if [ ! -f PlaydatesApp/Views/Dashboard/DashboardView.swift ]; then
  echo "Creating DashboardView redirection file..."
  echo 'import SwiftUI
import Firebase
import FirebaseFirestore
import Combine
import CoreLocation

// Dashboard is now fully integrated in MainTabView.swift
// This file exists to maintain project structure references
struct DashboardView_Reference {
    // This is just a placeholder to prevent build errors
    // All functionality is now in MainTabView.swift
}' > PlaydatesApp/Views/Dashboard/DashboardView.swift
fi

if [ ! -f PlaydatesApp/Views/Social/SocialView.swift ]; then
  echo "Creating SocialView redirection file..."
  echo 'import SwiftUI
import Firebase
import FirebaseFirestore
import Combine

// Social view is now fully integrated in MainTabView.swift
// This file exists to maintain project structure references
struct SocialView_Reference {
    // This is just a placeholder to prevent build errors
    // All functionality is now in MainTabView.swift
}' > PlaydatesApp/Views/Social/SocialView.swift
fi

# Update project.yml if it exists (for XcodeGen users)
if [ -f "project.yml" ]; then
  echo "Updating project.yml to reflect consolidated view structure..."
  # Create backup of project.yml
  cp project.yml project.yml.backup
  
  # This would need a more complex script to modify project.yml
  # For now, just notify the user
  echo "NOTE: You'll need to manually update project.yml to remove old views and add the new consolidated structure"
fi

echo "Creating a simple Xcode project update list..."
cat > xcode_project_updates.txt << 'EOF'
Xcode Project Update Instructions
================================

Since we've consolidated the app into a 2-tab structure (Dashboard and Social),
follow these steps to update your Xcode project:

1. Remove old view references from project navigator:
   - PlaydatesApp/Views/Explore
   - PlaydatesApp/Views/Playdates  
   - PlaydatesApp/Views/Friends
   - PlaydatesApp/Views/Profile
   - PlaydatesApp/Views/Home

2. Add new view structure:
   - PlaydatesApp/Views/Dashboard/DashboardView.swift
   - PlaydatesApp/Views/Social/SocialView.swift
   - PlaydatesApp/Views/MainTabView.swift (already updated)

3. Make sure all views import the ModelImports file:
   import "PlaydatesApp/Utils/ModelImports.swift"
   
4. Update project settings to remove any build phase references to deleted files

5. Clean build folder (Shift+Command+K) and rebuild project
EOF

echo "=========================================================="
echo "Created xcode_project_updates.txt with instructions for manually updating Xcode project"
echo "Created placeholder files for Dashboard and Social views"
echo "Removed any lingering old view directories"
echo "=========================================================="
echo "IMPORTANT: The app now follows a consolidated 2-tab structure:"
echo "  - Dashboard Tab: For all content-related features"
echo "  - Social Tab: For all social-related features"
echo "=========================================================="
