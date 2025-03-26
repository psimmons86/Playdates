import SwiftUI
import FirebaseFirestoreSwift

// Using the Child model from User.swift
// We'll create a wrapper to handle string-based age during input
struct ChildInput: Identifiable {
    var id = UUID().uuidString
    var name: String = ""
    var ageString: String = ""
    var interests: [String] = []
    
    init() {}
    
    // Convert to the app's Child model
    func toChild() -> Child {
        let ageInt = Int(ageString) ?? 0
        return Child(id: id, name: name, age: ageInt, interests: interests.isEmpty ? nil : interests)
    }
    
    // Create from the app's Child model
    static func from(_ child: Child) -> ChildInput {
        var input = ChildInput()
        input.id = child.id
        input.name = child.name
        input.ageString = String(child.age)
        input.interests = child.interests ?? []
        return input
    }
}

struct ChildProfileSetupView: View {
    @State private var childInputs: [ChildInput] = [ChildInput()]
    @State private var isLoading = false
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
                        ForEach(Array(childInputs.enumerated()), id: \.element.id) { index, _ in
                            ChildFormView(
                                index: index,
                                childInput: $childInputs[index],
                                interestOptions: interestOptions,
                                onRemove: {
                                    if childInputs.count > 1 {
                                        childInputs.remove(at: index)
                                    }
                                }
                            )
                        }
                        
                        // Add another child button
                        Button(action: {
                            childInputs.append(ChildInput())
                        }) {
                            Text("+ Add Another Child")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(ColorTheme.darkPurple)
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
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 16)
                }
                
                // Bottom buttons
                VStack(spacing: 16) {
                    Button(action: {
                        // Validate and save
                        if isFormValid {
                            isLoading = true
                            
                            // Convert ChildInput to Child models
                            let children = childInputs.map { $0.toChild() }
                            
                            // Here you would save the children to the user profile
                            // For now, we'll just simulate saving
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                isLoading = false
                                onComplete()
                            }
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(ColorTheme.highlight)
                                .cornerRadius(28)
                        } else {
                            Text("Continue")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isFormValid ? ColorTheme.highlight : ColorTheme.highlight.opacity(0.5))
                                .cornerRadius(28)
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                    
                    Button(action: onSkip) {
                        Text("Skip for Now")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(ColorTheme.primary)
                    }
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
                    Button(action: onRemove) {
                        Text("Remove")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
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
    }
}

// Flow layout for interests
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

struct ChildProfileSetupView_Previews: PreviewProvider {
    static var previews: some View {
        ChildProfileSetupView(
            onComplete: {},
            onSkip: {}
        )
    }
}
