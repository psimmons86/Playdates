import SwiftUI

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var postViewModel: PostViewModel // Inject or create instance
    @State private var postText: String = ""
    @State private var isPosting: Bool = false
    // TODO: Add state for image selection if implementing image uploads

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 15) {
                TextEditor(text: $postText)
                    .frame(height: 200) // Give it some initial height
                    .border(Color.gray.opacity(0.3), width: 1)
                    .cornerRadius(8)
                    .overlay(
                        // Placeholder text
                        postText.isEmpty ? Text("What's on your mind?").foregroundColor(.gray).padding(8) : nil,
                        alignment: .topLeading
                    )

                // TODO: Add Image Picker button here if needed

                Spacer() // Pushes content to top

                // Display error if any
                if let error = postViewModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding()
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        Task {
                            isPosting = true
                            await postViewModel.createPost(text: postText) // Add imageURL if implemented
                            isPosting = false
                            // Dismiss only if post creation was successful (no error)
                            if postViewModel.error == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPosting) // Disable if no text or currently posting
                    .overlay( // Show progress indicator on the button
                        isPosting ? ProgressView() : nil
                    )
                }
            }
        }
    }
}

// Preview Provider
struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a PostViewModel instance for the preview
        CreatePostView(postViewModel: PostViewModel())
    }
}
