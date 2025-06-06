import SwiftUI
import FirebaseFirestoreSwift

// Using the PlaydateChild model from User.swift
// We'll create a wrapper to handle string-based age during input
struct ChildInput: Identifiable {
    var id = UUID().uuidString
    var name: String = ""
    var ageString: String = ""
    var interests: [String] = []
    
    init() {}
    
    // Convert to the app's PlaydateChild model
    func toChild(parentID: String) -> PlaydateChild {
        let ageInt = Int(ageString) ?? 0
        return PlaydateChild(id: id, name: name, age: ageInt, interests: interests, parentID: parentID)
    }
    
    // Create from the app's PlaydateChild model
    static func from(_ child: PlaydateChild) -> ChildInput {
        var input = ChildInput()
        input.id = child.id ?? UUID().uuidString
        input.name = child.name
        input.ageString = String(child.age)
        input.interests = child.interests
        return input
    }
}

@available(iOS 17.0, *)
struct ChildProfileSetupView: View {
    @State private var childInputs: [ChildInput] = [ChildInput()]
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @ObservedObject private var authViewModel = AuthViewModel()
    private var onComplete: () -> Void
    private var onSkip: () -> Void
    
    init(onComplete: @escaping () -> Void, onSkip: @escaping () -> Void) {
        self.onComplete = onComplete
        self.onSkip = onSkip
    }
    
    let interestOptions = [
        "Sports", "Arts & Crafts", "Music", "Reading",
        "Dance", "Nature", "Science", "Board Games"
    ]
    
    var body: some View {
        ZStack {
            ColorTheme.background.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add Your Children")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.darkPurple)
                    
                    Text("Help us find the perfect playdates for your little ones")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.lightText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Child forms
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(0..<childInputs.count, id: \.self) { index in
                            ChildFormView(
                                index: index,
                                childInput: $childInputs[index],
                                interestOptions: interestOptions,
                                onRemove: {
                                    withAnimation {
                                        if childInputs.count > 1 {
                                            childInputs.remove(at: index)
                                            print("Removed child at index \(index), remaining: \(childInputs.count)")
                                        }
                                    }
                                }
                            )
                        }
                        
                        // Add another child button
                        Button(action: {
                            withAnimation {
                                let newChild = ChildInput()
                                childInputs.append(newChild)
                                print("Added new child, total count: \(childInputs.count)")
                            }
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(ColorTheme.darkPurple)
                                    .font(.system(size: 20))
                                
                                Text("Add Another Child")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(ColorTheme.darkPurple)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                    .foregroundColor(ColorTheme.accent)
                                    .background(ColorTheme.accent.opacity(0.1))
                                    .cornerRadius(12)
                            )
                        }
                        .buttonStyle(PlainButtonStyle()) // Keep PlainButtonStyle for custom background
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 16)
                }
                
                // Error message (if any)
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
                
                // Bottom buttons
                VStack(spacing: 16) {
                    Button(action: {
                        // Validate and save
                        if isFormValid {
                            isLoading = true
                            errorMessage = nil
                            
                            // Check if we have a current user
                            if var user = authViewModel.currentUser, let userID = user.id {
                                // Convert ChildInput to PlaydateChild models
                                let children = childInputs.map { $0.toChild(parentID: userID) }
                                
                                // Update the user's children
                                user.children = children
                                
                                // Save the updated user profile, including children
                                authViewModel.updateUserProfile(
                                    name: user.name,
                                    bio: user.bio,
                                    profileImageURL: user.profileImageURL,
                                    children: children // Pass the children array here
                                ) { success in
                                    isLoading = false

                                    if success {
                                        print("Successfully saved \(children.count) children to user profile")
                                        onComplete()
                                    } else {
                                        errorMessage = authViewModel.error ?? "Failed to save children"
                                    }
                                }
                            } else {
                                // No user is signed in or user data isn't loaded yet
                                isLoading = false
                                errorMessage = "User profile not available"
                                
                                // For onboarding, we'll still proceed even if saving fails
                                print("Warning: No user profile available, proceeding with onboarding")
                                onComplete()
                            }
                        }
                    }) {
                        // Label for the primary button
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(height: 20) // Match approx text height
                        } else {
                            Text("Continue")
                        }
                    }
                    .primaryStyle() // Apply primary style
                    .disabled(isLoading || !isFormValid)
                    
                    Button("Skip for Now") { // Use simple title init
                        onSkip()
                    }
                    .textStyle() // Apply text style
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
    }
    
    private var isFormValid: Bool {
        childInputs.allSatisfy { childInput in
            !childInput.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !childInput.ageString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

@available(iOS 17.0, *)
struct ChildFormView: View {
    let index: Int
    @Binding var childInput: ChildInput
    let interestOptions: [String]
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with remove button
            HStack {
                Text(index == 0 ? "First Child" : "Child \(index + 1)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorTheme.darkPurple)
                
                Spacer()
                
                if index > 0 {
                    Button("Remove") { // Use simple title init
                        onRemove()
                    }
                    .textStyle(color: .red) // Apply text style with red color
                }
            }
            
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Child's Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTheme.darkPurple)
                
                TextField("Enter name", text: $childInput.name)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            // Age field
            VStack(alignment: .leading, spacing: 8) {
                Text("Age")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTheme.darkPurple)
                
                TextField("Enter age", text: $childInput.ageString)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .onChange(of: childInput.ageString) { newValue in
                        // Only allow numbers
                        if newValue.isEmpty || newValue.allSatisfy({ $0.isNumber }) {
                            // Valid input, do nothing
                        } else {
                            // Invalid input, revert to previous value
                            childInput.ageString = newValue.filter { $0.isNumber }
                        }
                    }
            }
            
            // Interests
            VStack(alignment: .leading, spacing: 8) {
                Text("Interests (Optional)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTheme.darkPurple)
                
                FlowLayout(spacing: 8) {
                    ForEach(interestOptions, id: \.self) { interest in
                        InterestToggleButton(
                            interest: interest,
                            isSelected: childInput.interests.contains(interest),
                            onToggle: {
                                toggleInterest(interest)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private func toggleInterest(_ interest: String) {
        if childInput.interests.contains(interest) {
            childInput.interests.removeAll { $0 == interest }
        } else {
            childInput.interests.append(interest)
        }
    }
}

@available(iOS 17.0, *)
struct InterestToggleButton: View {
    let interest: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            Text(interest)
                .font(.caption)
                .fontWeight(isSelected ? .medium : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? ColorTheme.accent : Color.black.opacity(0.05))
                .foregroundColor(isSelected ? ColorTheme.darkPurple : ColorTheme.lightText)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle()) // Apply plain style for custom background
    }
}

// Flow layout for interests - iOS 17.0+ only
@available(iOS 17.0, *)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            if x + viewSize.width > width {
                // Move to next row
                y += maxHeight + spacing
                x = 0
                maxHeight = 0
            }
            
            maxHeight = max(maxHeight, viewSize.height)
            x += viewSize.width + spacing
        }
        
        height = y + maxHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            if x + viewSize.width > bounds.maxX {
                // Move to next row
                y += maxHeight + spacing
                x = bounds.minX
                maxHeight = 0
            }
            
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: viewSize.width, height: viewSize.height))
            
            maxHeight = max(maxHeight, viewSize.height)
            x += viewSize.width + spacing
        }
    }
}

@available(iOS 17.0, *)
struct ChildProfileSetupView_Previews: PreviewProvider {
    static var previews: some View {
        ChildProfileSetupView(
            onComplete: {},
            onSkip: {}
        )
    }
}
