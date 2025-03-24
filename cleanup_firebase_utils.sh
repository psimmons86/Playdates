#!/bin/bash

echo "Cleaning up PlaydatesApp after UI consolidation"
echo "=============================================="

# Create backup directory for removed files
BACKUP_DIR="./bk_removed_files"
mkdir -p $BACKUP_DIR

# 1. Move redundant utility files to backup
echo "Moving redundant utility files to backup..."
mv -f PlaydatesApp/Utils/FirebaseDataParser.swift $BACKUP_DIR/ 2>/dev/null || true
mv -f PlaydatesApp/Utils/SafeStringForwarding.swift $BACKUP_DIR/ 2>/dev/null || true
mv -f PlaydatesApp/Utils/RuntimePatches.swift $BACKUP_DIR/ 2>/dev/null || true
mv -f PlaydatesApp/Utils/GetBytesPatches.swift $BACKUP_DIR/ 2>/dev/null || true
mv -f PlaydatesApp/Utils/NSNumberSwizzle.swift $BACKUP_DIR/ 2>/dev/null || true
mv -f PlaydatesApp/Utils/NSNumberTest.swift $BACKUP_DIR/ 2>/dev/null || true

# 2. Move redundant Views after UI consolidation
echo "Moving redundant views after UI consolidation..."
mkdir -p $BACKUP_DIR/Views
mv -f PlaydatesApp/Views/Explore/ExploreView.swift $BACKUP_DIR/Views/ 2>/dev/null || true
mv -f PlaydatesApp/Views/Playdates/PlaydatesView.swift $BACKUP_DIR/Views/ 2>/dev/null || true
mv -f PlaydatesApp/Views/Friends/FriendsView.swift $BACKUP_DIR/Views/ 2>/dev/null || true
mv -f PlaydatesApp/Views/Profile/ProfileView.swift $BACKUP_DIR/Views/ 2>/dev/null || true
mv -f PlaydatesApp/Views/Home/HomeView.swift $BACKUP_DIR/Views/ 2>/dev/null || true

# 3. Create consolidated views directory structure
echo "Creating consolidated view directory structure..."
mkdir -p PlaydatesApp/Views/Dashboard
mkdir -p PlaydatesApp/Views/Social

# 4. Create empty dashboard and social view files if they don't exist yet
if [ ! -f PlaydatesApp/Views/Dashboard/DashboardView.swift ]; then
    echo "import SwiftUI
import Firebase
import FirebaseFirestore
import Combine
import CoreLocation

// Dashboard view is now contained in MainTabView.swift
" > PlaydatesApp/Views/Dashboard/DashboardView.swift
fi

if [ ! -f PlaydatesApp/Views/Social/SocialView.swift ]; then
    echo "import SwiftUI
import Firebase
import FirebaseFirestore
import Combine

// Social view is now contained in MainTabView.swift
" > PlaydatesApp/Views/Social/SocialView.swift
fi

# 5. Update imports in all ViewModels
echo "Updating imports in ViewModels..."
VIEWMODELS=("PlaydatesApp/ViewModels/AuthViewModel.swift" 
            "PlaydatesApp/ViewModels/PlaydateViewModel.swift" 
            "PlaydatesApp/ViewModels/ActivityViewModel.swift" 
            "PlaydatesApp/ViewModels/FriendshipViewModel.swift")

for file in "${VIEWMODELS[@]}"; do
    if [ -f "$file" ]; then
        # Check if ModelImports is already imported
        if ! grep -q "import.*ModelImports" "$file"; then
            # Add ModelImports import after Foundation import
            sed -i '' '/import Foundation/ a\
import "PlaydatesApp\/Utils\/ModelImports.swift"
' "$file"
            echo "Added ModelImports import to $file"
        fi
    fi
done

# 6. Update ContentView to use the new MainTabView
echo "Updating ContentView..."
if [ -f "PlaydatesApp/Views/ContentView.swift" ]; then
    cat > PlaydatesApp/Views/ContentView.swift << 'EOF'
import SwiftUI
import Firebase

struct ContentView: View {
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var playdateViewModel = PlaydateViewModel()
    @StateObject var activityViewModel = ActivityViewModel()
    @StateObject var friendshipViewModel = FriendshipViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isSignedIn {
                MainTabView(
                    authViewModel: authViewModel,
                    playdateViewModel: playdateViewModel,
                    activityViewModel: activityViewModel,
                    friendshipViewModel: friendshipViewModel
                )
            } else {
                AuthView(viewModel: authViewModel)
            }
        }
        .onAppear {
            authViewModel.checkAuthState()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
EOF
    echo "ContentView updated to use new MainTabView"
else
    echo "Warning: ContentView.swift not found"
fi

# 7. Update project imports for FirebaseSafetyKit
echo "Updating all Swift files with import for FirebaseSafetyKit..."
find PlaydatesApp -name "*.swift" -type f | while read file; do
    # Skip the ModelImports.swift file itself
    if [[ "$file" != *"ModelImports.swift"* ]]; then
        # Check if the file already imports ModelImports
        if ! grep -q "import.*ModelImports" "$file" && ! grep -q "import.*FirebaseSafetyKit" "$file"; then
            # Add ModelImports import after the first import statement
            sed -i '' '/^import/ a\
import "PlaydatesApp\/Utils\/ModelImports.swift"
' "$file"
            echo "Added ModelImports import to $file"
        fi
    fi
done

echo "=============================================="
echo "Cleanup complete! Removed redundant files are backed up to $BACKUP_DIR"
echo "You may need to restart Xcode or re-index the project to see all changes."
