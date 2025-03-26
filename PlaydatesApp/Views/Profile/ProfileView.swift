import SwiftUI
import Foundation
import CoreLocation
import MapKit
import Combine
import UIKit
import Firebase

// Profile View
public struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingChildSetupSheet = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile header
                VStack(spacing: 16) {
                    // Profile image
                    Circle()
                        .fill(ColorTheme.primary.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(ColorTheme.primary)
                        )
                    
                    // User name
                    Text(authViewModel.currentUser?.name ?? "User")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.darkPurple)
                    
                    // User info
                    Text(authViewModel.currentUser?.email ?? "user@example.com")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Children section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Your Children")
                            .font(.headline)
                            .foregroundColor(ColorTheme.darkPurple)
                        
                        Spacer()
                        
                        Button(action: {
                            showingChildSetupSheet = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.caption)
                                
                                Text("Add Child")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(ColorTheme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                    }
                    
                    if let children = authViewModel.currentUser?.children, !children.isEmpty {
                        ForEach(children, id: \.id) { child in
                            ChildProfileCard(child: child)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "person.and.person")
                                .font(.system(size: 40))
                                .foregroundColor(ColorTheme.lightText)
                            
                            Text("No children added yet")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.lightText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Settings section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Settings")
                        .font(.headline)
                        .foregroundColor(ColorTheme.darkPurple)
                    
                    SettingsRow(icon: "gear", title: "Account Settings")
                    SettingsRow(icon: "bell", title: "Notifications")
                    SettingsRow(icon: "lock", title: "Privacy")
                    SettingsRow(icon: "questionmark.circle", title: "Help & Support")
                    
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                            
                            Text("Sign Out")
                                .foregroundColor(.red)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(ColorTheme.lightText)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showingChildSetupSheet) {
            ChildProfileSetupView(
                onComplete: {
                    // Dismiss the sheet when the child is added successfully
                    showingChildSetupSheet = false
                },
                onSkip: {
                    // Dismiss the sheet when the user skips
                    showingChildSetupSheet = false
                }
            )
        }
    }
}

// Helper Views

struct ChildProfileCard: View {
    let child: PlaydateChild
    
    var body: some View {
        HStack(spacing: 16) {
            // Child image
            Circle()
                .fill(ColorTheme.accent.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(ColorTheme.accent)
                )
            
            // Child info
            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.headline)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Text("\(child.age) years old")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.lightText)
            }
            
            Spacer()
            
            // Edit button
            Button(action: {
                // Edit action
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(ColorTheme.primary)
                    .padding(8)
                    .background(ColorTheme.primary.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(ColorTheme.primary)
            
            Text(title)
                .foregroundColor(ColorTheme.darkPurple)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(ColorTheme.lightText)
        }
        .padding(.vertical, 8)
    }
}
